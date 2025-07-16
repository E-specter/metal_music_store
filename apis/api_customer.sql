-- =============================================
-- ESQUEMA API_CUSTOMER
-- =============================================

CREATE SCHEMA IF NOT EXISTS api_customer;

GRANT USAGE ON SCHEMA api_customer TO api_customer;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_customer GRANT EXECUTE ON FUNCTIONS TO api_customer;

-- Vista segura para clientes
CREATE VIEW api_customer.vista_segura_clientes AS
SELECT 
  id_usuario,
  nombres,
  apellidos,
  correo_electronico,
  telefono,
  esta_activo
FROM usuarios
WHERE id_usuario = current_setting('app.current_user_id')::UUID;

-- =============================================
-- FUNCIONES DE PERFIL
-- =============================================

CREATE OR REPLACE FUNCTION api_customer.obtener_mi_perfil(
  p_id_usuario UUID
) RETURNS JSONB AS $$
DECLARE
  v_perfil JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', id_usuario,
    'nombre_usuario', nombre_usuario,
    'nombres', nombres,
    'apellidos', apellidos,
    'correo', correo_electronico,
    'telefono', telefono,
    'direccion_principal', (
      SELECT jsonb_build_object(
        'direccion', direccion,
        'coordenadas', ST_AsGeoJSON(coordenadas)::jsonb
      )
      FROM ubicaciones
      WHERE id_ubicacion = u.id_ubicacion_principal
    ),
    'direcciones_adicionales', direcciones_adicionales,
    'fecha_registro', fecha_creacion
  ) INTO v_perfil
  FROM usuarios u
  WHERE id_usuario = p_id_usuario;

  RETURN jsonb_build_object('perfil', v_perfil);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.obtener_perfil_publico(
  p_id_usuario UUID
) RETURNS JSONB AS $$
DECLARE
  v_perfil JSONB;
BEGIN
  SELECT jsonb_build_object(
    'nombres', nombres,
    'apellidos', apellidos,
    'fecha_registro', fecha_creacion,
    'listas_publicas', (
      SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', id_lista_deseos,
        'nombre', nombre
      )), '[]'::jsonb)
      FROM listas_deseos
      WHERE id_usuario = u.id_usuario AND NOT es_privada
    )
  ) INTO v_perfil
  FROM usuarios u
  WHERE id_usuario = p_id_usuario;

  RETURN jsonb_build_object('perfil', v_perfil);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.actualizar_perfil(
  p_id_usuario UUID,
  p_nombres VARCHAR(100) DEFAULT NULL,
  p_apellidos VARCHAR(100) DEFAULT NULL,
  p_telefono VARCHAR(20) DEFAULT NULL,
  p_direcciones_adicionales JSONB DEFAULT NULL
) RETURNS JSONB AS $$
BEGIN
  -- Validar formato de teléfono peruano si se proporciona
  IF p_telefono IS NOT NULL AND p_telefono !~ '^9[0-9]{8}$' THEN
    RETURN jsonb_build_object('error', 'Teléfono debe ser un número peruano de 9 dígitos comenzando con 9');
  END IF;

  -- Validar estructura JSON de direcciones adicionales si se proporciona
  IF p_direcciones_adicionales IS NOT NULL AND jsonb_typeof(p_direcciones_adicionales) != 'array' THEN
    RETURN jsonb_build_object('error', 'Las direcciones adicionales deben ser un array JSON');
  END IF;

  UPDATE usuarios SET
    nombres = COALESCE(p_nombres, nombres),
    apellidos = COALESCE(p_apellidos, apellidos),
    telefono = COALESCE(p_telefono, telefono),
    direcciones_adicionales = COALESCE(p_direcciones_adicionales, direcciones_adicionales)
  WHERE id_usuario = p_id_usuario;

  RETURN jsonb_build_object('success', true, 'message', 'Perfil actualizado correctamente');
EXCEPTION
  WHEN others THEN
    RETURN jsonb_build_object('error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.cambiar_contrasena(
  p_id_usuario UUID,
  p_contrasena_actual TEXT,
  p_nueva_contrasena TEXT
) RETURNS JSONB AS $$
DECLARE
  v_current_hash TEXT;
BEGIN
  -- Obtener hash actual
  SELECT contrasena_hash INTO v_current_hash
  FROM usuarios
  WHERE id_usuario = p_id_usuario;

  -- Verificar contraseña actual
  IF v_current_hash != crypt(p_contrasena_actual, v_current_hash) THEN
    RETURN jsonb_build_object('error', 'La contraseña actual no es correcta');
  END IF;

  -- Actualizar contraseña
  UPDATE usuarios
  SET contrasena_hash = crypt(p_nueva_contrasena, gen_salt('bf'))
  WHERE id_usuario = p_id_usuario;

  RETURN jsonb_build_object('success', true, 'message', 'Contraseña actualizada correctamente');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- FUNCIONES DE PEDIDOS
-- =============================================

CREATE OR REPLACE FUNCTION api_customer.obtener_mis_pedidos(
  p_id_usuario UUID,
  p_pagina INTEGER DEFAULT 1,
  p_por_pagina INTEGER DEFAULT 10,
  p_estado VARCHAR DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_pedidos JSONB;
  v_total INTEGER;
  v_resultado JSONB;
BEGIN
  -- Contar total de pedidos
  SELECT COUNT(*) INTO v_total
  FROM pedidos
  WHERE id_usuario = p_id_usuario
    AND (p_estado IS NULL OR id_estado = (
      SELECT id_estado FROM estados_pedido WHERE codigo_estado = p_estado
    ));

  -- Obtener pedidos paginados
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', p.id_pedido,
      'numero_pedido', p.numero_pedido,
      'fecha', p.fecha_creacion,
      'estado', jsonb_build_object(
        'codigo', ep.codigo_estado,
        'nombre', ep.nombre_estado
      ),
      'total', p.total,
      'items', (
        SELECT jsonb_agg(jsonb_build_object(
          'nombre', pr.nombre,
          'cantidad', ip.cantidad,
          'precio_unitario', ip.precio_unitario
        ))
        FROM items_pedido ip
        JOIN productos pr ON ip.id_producto = pr.id_producto
        WHERE ip.id_pedido = p.id_pedido
      )
    )
    ORDER BY p.fecha_creacion DESC
  ), '[]'::jsonb) INTO v_pedidos
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE p.id_usuario = p_id_usuario
    AND (p_estado IS NULL OR ep.codigo_estado = p_estado)
  LIMIT p_por_pagina
  OFFSET (p_pagina - 1) * p_por_pagina;

  -- Construir respuesta con paginación
  SELECT jsonb_build_object(
    'pedidos', v_pedidos,
    'paginacion', jsonb_build_object(
      'pagina_actual', p_pagina,
      'por_pagina', p_por_pagina,
      'total', v_total,
      'total_paginas', CEIL(v_total::FLOAT / p_por_pagina)
    )
  ) INTO v_resultado;

  RETURN v_resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.obtener_detalle_pedido(
  p_id_usuario UUID,
  p_id_pedido UUID
) RETURNS JSONB AS $$
DECLARE
  v_pedido JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', p.id_pedido,
    'numero_pedido', p.numero_pedido,
    'fecha', p.fecha_creacion,
    'estado', jsonb_build_object(
      'codigo', ep.codigo_estado,
      'nombre', ep.nombre_estado,
      'es_final', ep.es_final
    ),
    'metodo_pago', jsonb_build_object(
      'nombre', mp.nombre,
      'descripcion', mp.descripcion
    ),
    'pago', jsonb_build_object(
      'estado', CASE WHEN p.estado_pago THEN 'pagado' ELSE 'pendiente' END,
      'subtotal', p.subtotal,
      'impuestos', p.impuestos,
      'envio', p.costo_envio,
      'total', p.total
    ),
    'direccion_entrega', p.direccion,
    'items', (
      SELECT jsonb_agg(jsonb_build_object(
        'id', ip.id_producto,
        'nombre', pr.nombre,
        'cantidad', ip.cantidad,
        'precio_unitario', ip.precio_unitario,
        'precio_total', ip.precio_total,
        'imagen', (
          SELECT url_imagen 
          FROM imagenes_productos 
          WHERE id_producto = pr.id_producto AND es_principal 
          LIMIT 1
        )
      ))
      FROM items_pedido ip
      JOIN productos pr ON ip.id_producto = pr.id_producto
      WHERE ip.id_pedido = p.id_pedido
    ),
    'historial_estados', (
      SELECT jsonb_agg(jsonb_build_object(
        'estado', ep.nombre_estado,
        'fecha', he.fecha_cambio,
        'notas', he.notas
      ) ORDER BY he.fecha_cambio DESC)
      FROM historial_estados_pedido he
      JOIN estados_pedido ep ON he.id_estado = ep.id_estado
      WHERE he.id_pedido = p.id_pedido
    )
  ) INTO v_pedido
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  LEFT JOIN metodos_pago mp ON p.id_metodo_pago = mp.id_metodo_pago
  WHERE p.id_pedido = p_id_pedido AND p.id_usuario = p_id_usuario;

  IF v_pedido IS NULL THEN
    RETURN jsonb_build_object('error', 'Pedido no encontrado o no pertenece al usuario');
  END IF;

  RETURN jsonb_build_object('pedido', v_pedido);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- FUNCIONES DE LISTAS DE DESEOS
-- =============================================

CREATE OR REPLACE FUNCTION api_customer.crear_lista_deseos(
  p_id_usuario UUID,
  p_nombre VARCHAR(100),
  p_descripcion TEXT DEFAULT NULL,
  p_es_privada BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
  v_id_lista UUID;
BEGIN
  -- Verificar que no exista otra lista con el mismo nombre para este usuario
  IF EXISTS (
    SELECT 1 FROM listas_deseos 
    WHERE id_usuario = p_id_usuario AND nombre = p_nombre
  ) THEN
    RETURN jsonb_build_object('error', 'Ya tienes una lista con ese nombre');
  END IF;

  INSERT INTO listas_deseos (
    id_usuario,
    nombre,
    descripcion,
    es_privada
  ) VALUES (
    p_id_usuario,
    p_nombre,
    p_descripcion,
    p_es_privada
  ) RETURNING id_lista_deseos INTO v_id_lista;

  RETURN jsonb_build_object(
    'success', true,
    'id_lista', v_id_lista,
    'message', 'Lista de deseos creada correctamente'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.obtener_mis_listas_deseos(
  p_id_usuario UUID
) RETURNS JSONB AS $$
DECLARE
  v_listas JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', id_lista_deseos,
      'nombre', nombre,
      'descripcion', descripcion,
      'es_privada', es_privada,
      'cantidad_items', (
        SELECT COUNT(*) 
        FROM items_lista_deseos 
        WHERE id_lista_deseos = ld.id_lista_deseos
      ),
      'fecha_creacion', fecha_creacion
    )
    ORDER BY fecha_creacion DESC
  ), '[]'::jsonb) INTO v_listas
  FROM listas_deseos ld
  WHERE id_usuario = p_id_usuario;

  RETURN jsonb_build_object('listas', v_listas);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.obtener_listas_publicas(
  p_pagina INTEGER DEFAULT 1,
  p_por_pagina INTEGER DEFAULT 10
) RETURNS JSONB AS $$
DECLARE
  v_listas JSONB;
  v_total INTEGER;
  v_resultado JSONB;
BEGIN
  -- Contar total de listas públicas
  SELECT COUNT(*) INTO v_total
  FROM listas_deseos
  WHERE NOT es_privada;

  -- Obtener listas paginadas
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', ld.id_lista_deseos,
      'nombre', ld.nombre,
      'descripcion', ld.descripcion,
      'usuario', jsonb_build_object(
        'nombres', u.nombres,
        'apellidos', u.apellidos
      ),
      'cantidad_items', (
        SELECT COUNT(*) 
        FROM items_lista_deseos 
        WHERE id_lista_deseos = ld.id_lista_deseos
      ),
      'items_recientes', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'id', p.id_producto,
            'nombre', p.nombre,
            'precio', p.precio,
            'imagen', (
              SELECT url_imagen 
              FROM imagenes_productos 
              WHERE id_producto = p.id_producto AND es_principal 
              LIMIT 1
            )
          )
          LIMIT 3
        ), '[]'::jsonb)
        FROM items_lista_deseos ild
        JOIN productos p ON ild.id_producto = p.id_producto
        WHERE ild.id_lista_deseos = ld.id_lista_deseos
        ORDER BY ild.fecha_agregado DESC
      )
    )
  ), '[]'::jsonb) INTO v_listas
  FROM listas_deseos ld
  JOIN usuarios u ON ld.id_usuario = u.id_usuario
  WHERE NOT ld.es_privada
  ORDER BY ld.fecha_creacion DESC
  LIMIT p_por_pagina
  OFFSET (p_pagina - 1) * p_por_pagina;

  -- Construir respuesta con paginación
  SELECT jsonb_build_object(
    'listas', v_listas,
    'paginacion', jsonb_build_object(
      'pagina_actual', p_pagina,
      'por_pagina', p_por_pagina,
      'total', v_total,
      'total_paginas', CEIL(v_total::FLOAT / p_por_pagina)
    )
  ) INTO v_resultado;

  RETURN v_resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.actualizar_lista_deseos(
  p_id_usuario UUID,
  p_id_lista UUID,
  p_nombre VARCHAR(100) DEFAULT NULL,
  p_descripcion TEXT DEFAULT NULL,
  p_es_privada BOOLEAN DEFAULT NULL
) RETURNS JSONB AS $$
BEGIN
  -- Verificar que la lista pertenezca al usuario
  IF NOT EXISTS (
    SELECT 1 FROM listas_deseos 
    WHERE id_lista_deseos = p_id_lista AND id_usuario = p_id_usuario
  ) THEN
    RETURN jsonb_build_object('error', 'Lista no encontrada o no tienes permisos');
  END IF;

  -- Verificar que el nuevo nombre no esté en uso
  IF p_nombre IS NOT NULL AND EXISTS (
    SELECT 1 FROM listas_deseos 
    WHERE id_usuario = p_id_usuario 
      AND nombre = p_nombre 
      AND id_lista_deseos != p_id_lista
  ) THEN
    RETURN jsonb_build_object('error', 'Ya tienes otra lista con ese nombre');
  END IF;

  UPDATE listas_deseos SET
    nombre = COALESCE(p_nombre, nombre),
    descripcion = COALESCE(p_descripcion, descripcion),
    es_privada = COALESCE(p_es_privada, es_privada)
  WHERE id_lista_deseos = p_id_lista;

  RETURN jsonb_build_object('success', true, 'message', 'Lista actualizada correctamente');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.eliminar_lista_deseos(
  p_id_usuario UUID,
  p_id_lista UUID
) RETURNS JSONB AS $$
BEGIN
  -- Verificar que la lista pertenezca al usuario
  IF NOT EXISTS (
    SELECT 1 FROM listas_deseos 
    WHERE id_lista_deseos = p_id_lista AND id_usuario = p_id_usuario
  ) THEN
    RETURN jsonb_build_object('error', 'Lista no encontrada o no tienes permisos');
  END IF;

  DELETE FROM listas_deseos 
  WHERE id_lista_deseos = p_id_lista;

  RETURN jsonb_build_object('success', true, 'message', 'Lista eliminada correctamente');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.agregar_producto_lista(
  p_id_usuario UUID,
  p_id_lista UUID,
  p_id_producto UUID
) RETURNS JSONB AS $$
BEGIN
  -- Verificar que la lista pertenezca al usuario
  IF NOT EXISTS (
    SELECT 1 FROM listas_deseos 
    WHERE id_lista_deseos = p_id_lista AND id_usuario = p_id_usuario
  ) THEN
    RETURN jsonb_build_object('error', 'Lista no encontrada o no tienes permisos');
  END IF;

  -- Verificar que el producto exista y esté activo
  IF NOT EXISTS (
    SELECT 1 FROM productos 
    WHERE id_producto = p_id_producto AND esta_activo
  ) THEN
    RETURN jsonb_build_object('error', 'Producto no encontrado o no disponible');
  END IF;

  -- Verificar que el producto no esté ya en la lista
  IF EXISTS (
    SELECT 1 FROM items_lista_deseos 
    WHERE id_lista_deseos = p_id_lista AND id_producto = p_id_producto
  ) THEN
    RETURN jsonb_build_object('error', 'Este producto ya está en la lista');
  END IF;

  INSERT INTO items_lista_deseos (
    id_lista_deseos,
    id_producto
  ) VALUES (
    p_id_lista,
    p_id_producto
  );

  RETURN jsonb_build_object('success', true, 'message', 'Producto agregado a la lista');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.eliminar_producto_lista(
  p_id_usuario UUID,
  p_id_lista UUID,
  p_id_producto UUID
) RETURNS JSONB AS $$
BEGIN
  -- Verificar que la lista pertenezca al usuario
  IF NOT EXISTS (
    SELECT 1 FROM listas_deseos 
    WHERE id_lista_deseos = p_id_lista AND id_usuario = p_id_usuario
  ) THEN
    RETURN jsonb_build_object('error', 'Lista no encontrada o no tienes permisos');
  END IF;

  DELETE FROM items_lista_deseos 
  WHERE id_lista_deseos = p_id_lista AND id_producto = p_id_producto;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Producto no encontrado en la lista');
  END IF;

  RETURN jsonb_build_object('success', true, 'message', 'Producto eliminado de la lista');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.obtener_detalle_lista_deseos(
  p_id_usuario UUID,
  p_id_lista UUID
) RETURNS JSONB AS $$
DECLARE
  v_lista JSONB;
  v_pertenece_al_usuario BOOLEAN;
BEGIN
  -- Verificar si la lista es privada y pertenece al usuario
  SELECT 
    jsonb_build_object(
      'id', ld.id_lista_deseos,
      'nombre', ld.nombre,
      'descripcion', ld.descripcion,
      'es_privada', ld.es_privada,
      'fecha_creacion', ld.fecha_creacion,
      'usuario', jsonb_build_object(
        'nombres', u.nombres,
        'apellidos', u.apellidos
      ),
      'items', COALESCE(
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'id', p.id_producto,
              'nombre', p.nombre,
              'precio', p.precio,
              'imagen', (
                SELECT url_imagen 
                FROM imagenes_productos 
                WHERE id_producto = p.id_producto AND es_principal 
                LIMIT 1
              ),
              'disponible', p.esta_activo AND p.cantidad_disponible > 0
            )
          )
          FROM items_lista_deseos ild
          JOIN productos p ON ild.id_producto = p.id_producto
          WHERE ild.id_lista_deseos = ld.id_lista_deseos
        ), '[]'::jsonb
      )
    ),
    (ld.id_usuario = p_id_usuario)
  INTO v_lista, v_pertenece_al_usuario
  FROM listas_deseos ld
  JOIN usuarios u ON ld.id_usuario = u.id_usuario
  WHERE ld.id_lista_deseos = p_id_lista
    AND (NOT ld.es_privada OR ld.id_usuario = p_id_usuario);

  IF v_lista IS NULL THEN
    RETURN jsonb_build_object('error', 'Lista no encontrada o es privada');
  END IF;

  -- Agregar flag de pertenencia
  SELECT jsonb_set(v_lista, '{pertenece_al_usuario}', to_jsonb(v_pertenece_al_usuario)) INTO v_lista;

  RETURN jsonb_build_object('lista', v_lista);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- FUNCIONES DE CARRITO DE COMPRAS
-- =============================================

CREATE OR REPLACE FUNCTION api_customer.obtener_mi_carrito(
  p_id_usuario UUID
) RETURNS JSONB AS $$
DECLARE
  v_id_carrito UUID;
  v_carrito JSONB;
BEGIN
  -- Obtener o crear carrito
  SELECT id_carrito INTO v_id_carrito
  FROM carritos_compras
  WHERE id_usuario = p_id_usuario;

  IF v_id_carrito IS NULL THEN
    INSERT INTO carritos_compras (id_usuario)
    VALUES (p_id_usuario)
    RETURNING id_carrito INTO v_id_carrito;
  END IF;

  -- Obtener items del carrito
  SELECT jsonb_build_object(
    'id_carrito', v_id_carrito,
    'items', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id_item', ic.id_item_carrito,
            'id_producto', p.id_producto,
            'nombre', p.nombre,
            'precio', p.precio,
            'cantidad', ic.cantidad,
            'subtotal', (p.precio * ic.cantidad),
            'imagen', (
              SELECT url_imagen 
              FROM imagenes_productos 
              WHERE id_producto = p.id_producto AND es_principal 
              LIMIT 1
            ),
            'disponible', p.esta_activo AND p.cantidad_disponible >= ic.cantidad
          )
        )
        FROM items_carrito ic
        JOIN productos p ON ic.id_producto = p.id_producto
        WHERE ic.id_carrito = v_id_carrito
      ), '[]'::jsonb
    ),
    'resumen', (
      SELECT jsonb_build_object(
        'subtotal', SUM(p.precio * ic.cantidad),
        'total_items', SUM(ic.cantidad),
        'total_productos', COUNT(*)
      )
      FROM items_carrito ic
      JOIN productos p ON ic.id_producto = p.id_producto
      WHERE ic.id_carrito = v_id_carrito
    )
  ) INTO v_carrito;

  RETURN v_carrito;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.agregar_producto_carrito(
  p_id_usuario UUID,
  p_id_producto UUID,
  p_cantidad INTEGER DEFAULT 1
) RETURNS JSONB AS $$
DECLARE
  v_id_carrito UUID;
  v_disponibilidad INTEGER;
BEGIN
  -- Validar cantidad
  IF p_cantidad < 1 THEN
    RETURN jsonb_build_object('error', 'La cantidad debe ser al menos 1');
  END IF;

  -- Verificar disponibilidad del producto
  SELECT cantidad_disponible INTO v_disponibilidad
  FROM productos
  WHERE id_producto = p_id_producto AND esta_activo;

  IF v_disponibilidad IS NULL THEN
    RETURN jsonb_build_object('error', 'Producto no encontrado o no disponible');
  END IF;

  IF v_disponibilidad < p_cantidad THEN
    RETURN jsonb_build_object(
      'error', 'No hay suficiente stock',
      'disponible', v_disponibilidad
    );
  END IF;

  -- Obtener o crear carrito
  SELECT id_carrito INTO v_id_carrito
  FROM carritos_compras
  WHERE id_usuario = p_id_usuario;

  IF v_id_carrito IS NULL THEN
    INSERT INTO carritos_compras (id_usuario)
    VALUES (p_id_usuario)
    RETURNING id_carrito INTO v_id_carrito;
  END IF;

  -- Agregar o actualizar producto en carrito
  INSERT INTO items_carrito (
    id_carrito,
    id_producto,
    cantidad
  ) VALUES (
    v_id_carrito,
    p_id_producto,
    p_cantidad
  ) ON CONFLICT (id_carrito, id_producto) 
  DO UPDATE SET cantidad = items_carrito.cantidad + EXCLUDED.cantidad;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Producto agregado al carrito',
    'id_carrito', v_id_carrito
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.actualizar_cantidad_carrito(
  p_id_usuario UUID,
  p_id_item_carrito INTEGER,
  p_cantidad INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_id_carrito UUID;
  v_disponibilidad INTEGER;
  v_id_producto UUID;
BEGIN
  -- Validar cantidad
  IF p_cantidad < 1 THEN
    RETURN jsonb_build_object('error', 'La cantidad debe ser al menos 1');
  END IF;

  -- Verificar que el item pertenezca al usuario
  SELECT cc.id_carrito, ic.id_producto INTO v_id_carrito, v_id_producto
  FROM items_carrito ic
  JOIN carritos_compras cc ON ic.id_carrito = cc.id_carrito
  WHERE ic.id_item_carrito = p_id_item_carrito
    AND cc.id_usuario = p_id_usuario;

  IF v_id_carrito IS NULL THEN
    RETURN jsonb_build_object('error', 'Ítem no encontrado o no pertenece al usuario');
  END IF;

  -- Verificar disponibilidad
  SELECT cantidad_disponible INTO v_disponibilidad
  FROM productos
  WHERE id_producto = v_id_producto AND esta_activo;

  IF v_disponibilidad < p_cantidad THEN
    RETURN jsonb_build_object(
      'error', 'No hay suficiente stock',
      'disponible', v_disponibilidad
    );
  END IF;

  -- Actualizar cantidad
  UPDATE items_carrito
  SET cantidad = p_cantidad
  WHERE id_item_carrito = p_id_item_carrito;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Cantidad actualizada',
    'id_carrito', v_id_carrito
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.eliminar_producto_carrito(
  p_id_usuario UUID,
  p_id_item_carrito INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_id_carrito UUID;
BEGIN
  -- Verificar que el item pertenezca al usuario
  SELECT cc.id_carrito INTO v_id_carrito
  FROM items_carrito ic
  JOIN carritos_compras cc ON ic.id_carrito = cc.id_carrito
  WHERE ic.id_item_carrito = p_id_item_carrito
    AND cc.id_usuario = p_id_usuario;

  IF v_id_carrito IS NULL THEN
    RETURN jsonb_build_object('error', 'Ítem no encontrado o no pertenece al usuario');
  END IF;

  -- Eliminar item
  DELETE FROM items_carrito
  WHERE id_item_carrito = p_id_item_carrito;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Producto eliminado del carrito',
    'id_carrito', v_id_carrito
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_customer.mover_lista_a_carrito(
  p_id_usuario UUID,
  p_id_lista UUID
) RETURNS JSONB AS $$
DECLARE
  v_id_carrito UUID;
  v_productos_no_disponibles JSONB;
BEGIN
  -- Verificar que la lista pertenezca al usuario
  IF NOT EXISTS (
    SELECT 1 FROM listas_deseos 
    WHERE id_lista_deseos = p_id_lista AND id_usuario = p_id_usuario
  ) THEN
    RETURN jsonb_build_object('error', 'Lista no encontrada o no tienes permisos');
  END IF;

  -- Obtener o crear carrito
  SELECT id_carrito INTO v_id_carrito
  FROM carritos_compras
  WHERE id_usuario = p_id_usuario;

  IF v_id_carrito IS NULL THEN
    INSERT INTO carritos_compras (id_usuario)
    VALUES (p_id_usuario)
    RETURNING id_carrito INTO v_id_carrito;
  END IF;

  -- Mover productos disponibles (ignorar los no disponibles)
  WITH productos_lista AS (
    SELECT ild.id_producto, 1 AS cantidad
    FROM items_lista_deseos ild
    JOIN productos p ON ild.id_producto = p.id_producto
    WHERE ild.id_lista_deseos = p_id_lista
      AND p.esta_activo
      AND p.cantidad_disponible > 0
  )
  INSERT INTO items_carrito (id_carrito, id_producto, cantidad)
  SELECT v_id_carrito, id_producto, cantidad
  FROM productos_lista
  ON CONFLICT (id_carrito, id_producto) 
  DO UPDATE SET cantidad = items_carrito.cantidad + EXCLUDED.cantidad;

  -- Obtener lista de productos no disponibles para informar al usuario
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', p.id_producto,
      'nombre', p.nombre
    )
  ), '[]'::jsonb) INTO v_productos_no_disponibles
  FROM items_lista_deseos ild
  JOIN productos p ON ild.id_producto = p.id_producto
  WHERE ild.id_lista_deseos = p_id_lista
    AND (NOT p.esta_activo OR p.cantidad_disponible <= 0);

  RETURN jsonb_build_object(
    'success', true,
    'message', CASE 
      WHEN jsonb_array_length(v_productos_no_disponibles) > 0 THEN 
        'Productos disponibles agregados al carrito (algunos no estaban disponibles)'
      ELSE 
        'Todos los productos fueron agregados al carrito'
    END,
    'productos_no_disponibles', v_productos_no_disponibles,
    'id_carrito', v_id_carrito
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

--------------------------------------------------------------
-- Para búsqueda de pedidos por usuario
CREATE INDEX idx_pedidos_usuario ON pedidos(id_usuario);

-- Para items de carrito
CREATE INDEX idx_items_carrito ON items_carrito(id_carrito, id_producto);

-- Para listas de deseos
CREATE INDEX idx_listas_deseos_usuario ON listas_deseos(id_usuario);
CREATE INDEX idx_items_lista_deseos ON items_lista_deseos(id_lista_deseos, id_producto);

-- Para carritos de compra
ALTER TABLE carritos_compras ENABLE ROW LEVEL SECURITY;
CREATE POLICY carritos_usuario ON carritos_compras
  FOR ALL TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID);

-- Para listas de deseos
ALTER TABLE listas_deseos ENABLE ROW LEVEL SECURITY;
CREATE POLICY listas_propias ON listas_deseos
  FOR ALL TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID);

  -- Para carritos de compra
ALTER TABLE carritos_compras ENABLE ROW LEVEL SECURITY;
CREATE POLICY carritos_usuario ON carritos_compras
  FOR ALL TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID);

-- Para listas de deseos
ALTER TABLE listas_deseos ENABLE ROW LEVEL SECURITY;
CREATE POLICY listas_propias ON listas_deseos
  FOR ALL TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID);