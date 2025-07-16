-- =============================================
-- ESQUEMA API_ADMIN
-- =============================================

CREATE SCHEMA IF NOT EXISTS api_admin;

GRANT USAGE ON SCHEMA api_admin TO api_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_admin GRANT EXECUTE ON FUNCTIONS TO api_admin;

-- Vista segura para admins
CREATE VIEW api_admin.vista_segura_usuarios AS
SELECT 
  u.id_usuario,
  u.nombres,
  u.apellidos,
  u.correo_electronico,
  u.telefono,
  u.esta_activo,
  r.nombre_rol AS rol,
  u.fecha_creacion
FROM usuarios u
JOIN roles r ON u.id_rol = r.id_rol;

-- =============================================
-- FUNCIONES DE PERFIL ADMIN
-- =============================================

CREATE OR REPLACE FUNCTION api_admin.obtener_mi_perfil(
  p_id_admin UUID
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
    'rol', (SELECT nombre_rol FROM roles WHERE id_rol = usuarios.id_rol),
    'fecha_registro', fecha_creacion,
    'permisos', (SELECT permisos FROM roles WHERE id_rol = usuarios.id_rol)
  ) INTO v_perfil
  FROM usuarios
  WHERE id_usuario = p_id_admin 
    AND id_rol IN (SELECT id_rol FROM roles WHERE nombre_rol IN ('admin', 'superadmin'));

  IF v_perfil IS NULL THEN
    RETURN jsonb_build_object('error', 'Administrador no encontrado o no tiene privilegios');
  END IF;

  RETURN jsonb_build_object('perfil', v_perfil);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_admin.actualizar_perfil_admin(
  p_id_admin UUID,
  p_nombres VARCHAR(100) DEFAULT NULL,
  p_apellidos VARCHAR(100) DEFAULT NULL
) RETURNS JSONB AS $$
BEGIN
  -- Solo permite actualizar nombres y apellidos
  UPDATE usuarios SET
    nombres = COALESCE(p_nombres, nombres),
    apellidos = COALESCE(p_apellidos, apellidos)
  WHERE id_usuario = p_id_admin
    AND id_rol IN (SELECT id_rol FROM roles WHERE nombre_rol IN ('admin', 'superadmin'));

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Administrador no encontrado o no tiene privilegios');
  END IF;

  RETURN jsonb_build_object('success', true, 'message', 'Perfil actualizado correctamente');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_admin.cambiar_contrasena_admin(
  p_id_admin UUID,
  p_contrasena_actual TEXT,
  p_nueva_contrasena TEXT
) RETURNS JSONB AS $$
DECLARE
  v_current_hash TEXT;
BEGIN
  -- Obtener hash actual verificando rol
  SELECT contrasena_hash INTO v_current_hash
  FROM usuarios
  WHERE id_usuario = p_id_admin
    AND id_rol IN (SELECT id_rol FROM roles WHERE nombre_rol IN ('admin', 'superadmin'));

  IF v_current_hash IS NULL THEN
    RETURN jsonb_build_object('error', 'Administrador no encontrado o no tiene privilegios');
  END IF;

  -- Verificar contraseña actual
  IF v_current_hash != crypt(p_contrasena_actual, v_current_hash) THEN
    RETURN jsonb_build_object('error', 'La contraseña actual no es correcta');
  END IF;

  -- Actualizar contraseña
  UPDATE usuarios
  SET contrasena_hash = crypt(p_nueva_contrasena, gen_salt('bf'))
  WHERE id_usuario = p_id_admin;

  RETURN jsonb_build_object('success', true, 'message', 'Contraseña actualizada correctamente');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- FUNCIONES DE GESTIÓN DE PEDIDOS
-- =============================================

CREATE OR REPLACE FUNCTION api_admin.obtener_todos_pedidos(
  p_pagina INTEGER DEFAULT 1,
  p_por_pagina INTEGER DEFAULT 20,
  p_estado VARCHAR DEFAULT NULL,
  p_desde DATE DEFAULT NULL,
  p_hasta DATE DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_pedidos JSONB;
  v_total INTEGER;
  v_resultado JSONB;
BEGIN
  -- Contar total de pedidos con filtros
  SELECT COUNT(*) INTO v_total
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE (p_estado IS NULL OR ep.codigo_estado = p_estado)
    AND (p_desde IS NULL OR p.fecha_creacion >= p_desde)
    AND (p_hasta IS NULL OR p.fecha_creacion <= p_hasta + INTERVAL '1 day');

  -- Obtener pedidos paginados
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', p.id_pedido,
      'numero_pedido', p.numero_pedido,
      'fecha', p.fecha_creacion,
      'estado', jsonb_build_object(
        'codigo', ep.codigo_estado,
        'nombre', ep.nombre_estado,
        'es_final', ep.es_final
      ),
      'cliente', jsonb_build_object(
        'id', u.id_usuario,
        'nombre', u.nombres || ' ' || u.apellidos
      ),
      'total', p.total,
      'pago', CASE WHEN p.estado_pago THEN 'pagado' ELSE 'pendiente' END
    )
    ORDER BY p.fecha_creacion DESC
  ), '[]'::jsonb) INTO v_pedidos
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  JOIN usuarios u ON p.id_usuario = u.id_usuario
  WHERE (p_estado IS NULL OR ep.codigo_estado = p_estado)
    AND (p_desde IS NULL OR p.fecha_creacion >= p_desde)
    AND (p_hasta IS NULL OR p.fecha_creacion <= p_hasta + INTERVAL '1 day')
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

CREATE OR REPLACE FUNCTION api_admin.obtener_detalle_pedido_admin(
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
    'cliente', jsonb_build_object(
      'id', u.id_usuario,
      'nombre_completo', u.nombres || ' ' || u.apellidos,
      'correo', u.correo_electronico,
      'telefono', u.telefono
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
    'coordenadas_entrega', ST_AsGeoJSON(p.coordenadas)::jsonb,
    'items', (
      SELECT jsonb_agg(jsonb_build_object(
        'id', ip.id_producto,
        'nombre', pr.nombre,
        'cantidad', ip.cantidad,
        'precio_unitario', ip.precio_unitario,
        'precio_total', ip.precio_total,
        'descuento', ip.descuento,
        'impuestos', ip.impuestos,
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
        'usuario', COALESCE(u.nombres || ' ' || u.apellidos, 'Sistema'),
        'notas', he.notas
      ) ORDER BY he.fecha_cambio DESC)
      FROM historial_estados_pedido he
      JOIN estados_pedido ep ON he.id_estado = ep.id_estado
      LEFT JOIN usuarios u ON he.id_usuario = u.id_usuario
      WHERE he.id_pedido = p.id_pedido
    ),
    'notas', p.notas
  ) INTO v_pedido
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  JOIN usuarios u ON p.id_usuario = u.id_usuario
  LEFT JOIN metodos_pago mp ON p.id_metodo_pago = mp.id_metodo_pago
  WHERE p.id_pedido = p_id_pedido;

  IF v_pedido IS NULL THEN
    RETURN jsonb_build_object('error', 'Pedido no encontrado');
  END IF;

  RETURN jsonb_build_object('pedido', v_pedido);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_admin.actualizar_estado_pedido(
  p_id_admin UUID,
  p_id_pedido UUID,
  p_nuevo_estado VARCHAR,
  p_notas TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_id_estado INTEGER;
  v_es_final BOOLEAN;
  v_estado_actual VARCHAR;
BEGIN
  -- Obtener el ID del nuevo estado
  SELECT id_estado, es_final INTO v_id_estado, v_es_final
  FROM estados_pedido
  WHERE codigo_estado = p_nuevo_estado;

  IF v_id_estado IS NULL THEN
    RETURN jsonb_build_object('error', 'Estado no válido');
  END IF;

  -- Obtener estado actual del pedido
  SELECT ep.codigo_estado INTO v_estado_actual
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE p.id_pedido = p_id_pedido;

  IF v_estado_actual IS NULL THEN
    RETURN jsonb_build_object('error', 'Pedido no encontrado');
  END IF;

  -- Validar transición de estados
  IF v_estado_actual = 'cancelado' AND p_nuevo_estado != 'cancelado' THEN
    RETURN jsonb_build_object('error', 'Pedido cancelado no puede cambiar de estado');
  END IF;

  IF v_estado_actual = 'entregado' AND p_nuevo_estado != 'entregado' THEN
    RETURN jsonb_build_object('error', 'Pedido entregado no puede cambiar de estado');
  END IF;

  -- Actualizar estado del pedido
  UPDATE pedidos
  SET id_estado = v_id_estado
  WHERE id_pedido = p_id_pedido;

  -- Registrar en historial
  INSERT INTO historial_estados_pedido (
    id_pedido, id_estado, id_usuario, notas
  ) VALUES (
    p_id_pedido, v_id_estado, p_id_admin, p_notas
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Estado del pedido actualizado',
    'nuevo_estado', p_nuevo_estado,
    'es_final', v_es_final
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- FUNCIONES DE GESTIÓN DE CLIENTES
-- =============================================

CREATE OR REPLACE FUNCTION api_admin.obtener_todos_clientes(
  p_pagina INTEGER DEFAULT 1,
  p_por_pagina INTEGER DEFAULT 20,
  p_activos BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
  v_clientes JSONB;
  v_total INTEGER;
  v_resultado JSONB;
BEGIN
  -- Contar total de clientes
  SELECT COUNT(*) INTO v_total
  FROM usuarios
  WHERE id_rol = (SELECT id_rol FROM roles WHERE nombre_rol = 'cliente')
    AND esta_activo = p_activos;

  -- Obtener clientes paginados
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', id_usuario,
      'nombre_completo', nombres || ' ' || apellidos,
      'correo', correo_electronico,
      'telefono', telefono,
      'fecha_registro', fecha_creacion,
      'ultimo_acceso', ultimo_acceso,
      'esta_activo', esta_activo,
      'total_pedidos', (
        SELECT COUNT(*) 
        FROM pedidos 
        WHERE id_usuario = u.id_usuario
      ),
      'pedidos_recientes', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'id', p.id_pedido,
            'fecha', p.fecha_creacion,
            'total', p.total,
            'estado', ep.nombre_estado
          )
          ORDER BY p.fecha_creacion DESC
          LIMIT 3
        ), '[]'::jsonb)
        FROM pedidos p
        JOIN estados_pedido ep ON p.id_estado = ep.id_estado
        WHERE p.id_usuario = u.id_usuario
      )
    )
  ), '[]'::jsonb) INTO v_clientes
  FROM usuarios u
  WHERE id_rol = (SELECT id_rol FROM roles WHERE nombre_rol = 'cliente')
    AND esta_activo = p_activos
  ORDER BY nombres, apellidos
  LIMIT p_por_pagina
  OFFSET (p_pagina - 1) * p_por_pagina;

  -- Construir respuesta con paginación
  SELECT jsonb_build_object(
    'clientes', v_clientes,
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

CREATE OR REPLACE FUNCTION api_admin.obtener_detalle_cliente(
  p_id_cliente UUID
) RETURNS JSONB AS $$
DECLARE
  v_cliente JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', id_usuario,
    'nombre_usuario', nombre_usuario,
    'nombres', nombres,
    'apellidos', apellidos,
    'correo', correo_electronico,
    'telefono', telefono,
    'fecha_registro', fecha_creacion,
    'ultimo_acceso', ultimo_acceso,
    'esta_activo', esta_activo,
    'direccion_principal', (
      SELECT jsonb_build_object(
        'direccion', direccion,
        'coordenadas', ST_AsGeoJSON(coordenadas)::jsonb
      )
      FROM ubicaciones
      WHERE id_ubicacion = u.id_ubicacion_principal
    ),
    'direcciones_adicionales', direcciones_adicionales,
    'estadisticas', jsonb_build_object(
      'total_pedidos', (
        SELECT COUNT(*) 
        FROM pedidos 
        WHERE id_usuario = u.id_usuario
      ),
      'pedidos_completados', (
        SELECT COUNT(*) 
        FROM pedidos p
        JOIN estados_pedido ep ON p.id_estado = ep.id_estado
        WHERE p.id_usuario = u.id_usuario
          AND ep.es_final AND ep.codigo_estado != 'cancelado'
      ),
      'total_gastado', (
        SELECT COALESCE(SUM(total), 0)
        FROM pedidos
        WHERE id_usuario = u.id_usuario
      )
    ),
    'listas_deseos', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', id_lista_deseos,
          'nombre', nombre,
          'es_privada', es_privada,
          'cantidad_items', (
            SELECT COUNT(*) 
            FROM items_lista_deseos 
            WHERE id_lista_deseos = ld.id_lista_deseos
          )
        )
      ), '[]'::jsonb)
      FROM listas_deseos ld
      WHERE ld.id_usuario = u.id_usuario
    )
  ) INTO v_cliente
  FROM usuarios u
  WHERE id_usuario = p_id_cliente
    AND id_rol = (SELECT id_rol FROM roles WHERE nombre_rol = 'cliente');

  IF v_cliente IS NULL THEN
    RETURN jsonb_build_object('error', 'Cliente no encontrado o no es un cliente válido');
  END IF;

  RETURN jsonb_build_object('cliente', v_cliente);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_admin.obtener_pedidos_cliente(
  p_id_cliente UUID,
  p_pagina INTEGER DEFAULT 1,
  p_por_pagina INTEGER DEFAULT 10
) RETURNS JSONB AS $$
DECLARE
  v_pedidos JSONB;
  v_total INTEGER;
  v_resultado JSONB;
BEGIN
  -- Verificar que el usuario es un cliente
  IF NOT EXISTS (
    SELECT 1 FROM usuarios 
    WHERE id_usuario = p_id_cliente
      AND id_rol = (SELECT id_rol FROM roles WHERE nombre_rol = 'cliente')
  ) THEN
    RETURN jsonb_build_object('error', 'ID no corresponde a un cliente válido');
  END IF;

  -- Contar total de pedidos del cliente
  SELECT COUNT(*) INTO v_total
  FROM pedidos
  WHERE id_usuario = p_id_cliente;

  -- Obtener pedidos paginados
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', p.id_pedido,
      'numero_pedido', p.numero_pedido,
      'fecha', p.fecha_creacion,
      'estado', jsonb_build_object(
        'codigo', ep.codigo_estado,
        'nombre', ep.nombre_estado,
        'es_final', ep.es_final
      ),
      'total', p.total,
      'pago', CASE WHEN p.estado_pago THEN 'pagado' ELSE 'pendiente' END,
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
  WHERE p.id_usuario = p_id_cliente
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

-- =============================================
-- FUNCIONES DE GESTIÓN DE PRODUCTOS
-- =============================================

CREATE OR REPLACE FUNCTION api_admin.actualizar_producto(
  p_id_admin UUID,
  p_id_producto UUID,
  p_nombre VARCHAR(255) DEFAULT NULL,
  p_descripcion TEXT DEFAULT NULL,
  p_precio DECIMAL(10, 2) DEFAULT NULL,
  p_cantidad_disponible INTEGER DEFAULT NULL,
  p_id_categoria INTEGER DEFAULT NULL,
  p_marca VARCHAR(100) DEFAULT NULL,
  p_talla VARCHAR(50) DEFAULT NULL,
  p_esta_activo BOOLEAN DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_producto_anterior JSONB;
BEGIN
  -- Obtener datos actuales para auditoría
  SELECT to_jsonb(productos) INTO v_producto_anterior
  FROM productos
  WHERE id_producto = p_id_producto;

  -- Actualizar campos no nulos
  UPDATE productos SET
    nombre = COALESCE(p_nombre, nombre),
    descripcion = COALESCE(p_descripcion, descripcion),
    precio = COALESCE(p_precio, precio),
    cantidad_disponible = COALESCE(p_cantidad_disponible, cantidad_disponible),
    id_categoria = COALESCE(p_id_categoria, id_categoria),
    marca = COALESCE(p_marca, marca),
    talla = COALESCE(p_talla, talla),
    esta_activo = COALESCE(p_esta_activo, esta_activo)
  WHERE id_producto = p_id_producto;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Producto no encontrado');
  END IF;

  -- Registrar cambio de precio si aplica
  IF p_precio IS NOT NULL AND v_producto_anterior->>'precio' != p_precio::text THEN
    INSERT INTO historial_precios (
      id_producto, precio_anterior, precio_nuevo, modificado_por, razon_cambio
    ) VALUES (
      p_id_producto, 
      (v_producto_anterior->>'precio')::DECIMAL(10, 2), 
      p_precio, 
      p_id_admin,
      'Actualización manual por administrador'
    );
  END IF;

  -- Registrar cambio de stock si aplica
  IF p_cantidad_disponible IS NOT NULL AND 
     (v_producto_anterior->>'cantidad_disponible')::INTEGER != p_cantidad_disponible THEN
    INSERT INTO registro_inventario (
      id_producto, cambio_cantidad, nueva_cantidad, tipo_cambio, modificado_por
    ) VALUES (
      p_id_producto,
      p_cantidad_disponible - (v_producto_anterior->>'cantidad_disponible')::INTEGER,
      p_cantidad_disponible,
      'ajuste',
      p_id_admin
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Producto actualizado correctamente',
    'id_producto', p_id_producto
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_admin.actualizar_detalles_tecnicos(
  p_id_admin UUID,
  p_id_detalle_producto INTEGER,
  p_tipo_producto VARCHAR(50) DEFAULT NULL,
  p_peso DECIMAL(10, 2) DEFAULT NULL,
  p_dimensiones DECIMAL(10, 2)[] DEFAULT NULL,
  p_material_principal VARCHAR(100) DEFAULT NULL,
  p_materiales_secundarios JSONB DEFAULT NULL,
  p_cuidados_especiales JSONB DEFAULT NULL,
  p_especificaciones JSONB DEFAULT NULL
) RETURNS JSONB AS $$
BEGIN
  -- Actualizar campos no nulos
  UPDATE detalles_productos SET
    tipo_producto = COALESCE(p_tipo_producto, tipo_producto),
    peso = COALESCE(p_peso, peso),
    dimensiones = COALESCE(p_dimensiones, dimensiones),
    material_principal = COALESCE(p_material_principal, material_principal),
    materiales_secundarios = COALESCE(p_materiales_secundarios, materiales_secundarios),
    cuidados_especiales = COALESCE(p_cuidados_especiales, cuidados_especiales),
    especificaciones = COALESCE(p_especificaciones, especificaciones)
  WHERE id_detalle_producto = p_id_detalle_producto;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Detalle técnico no encontrado');
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Detalles técnicos actualizados correctamente',
    'id_detalle_producto', p_id_detalle_producto
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_admin.agregar_imagen_producto(
  p_id_admin UUID,
  p_id_producto UUID,
  p_url_imagen VARCHAR(255),
  p_texto_alternativo VARCHAR(255) DEFAULT NULL,
  p_es_principal BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS $$
BEGIN
  -- Verificar que el producto existe
  IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
    RETURN jsonb_build_object('error', 'Producto no encontrado');
  END IF;

  -- Si se marca como principal, quitar principal de otras imágenes
  IF p_es_principal THEN
    UPDATE imagenes_productos
    SET es_principal = FALSE
    WHERE id_producto = p_id_producto;
  END IF;

  -- Insertar nueva imagen
  INSERT INTO imagenes_productos (
    id_producto, url_imagen, texto_alternativo, es_principal
  ) VALUES (
    p_id_producto, p_url_imagen, p_texto_alternativo, p_es_principal
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Imagen agregada correctamente',
    'id_producto', p_id_producto
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_admin.actualizar_imagen_producto(
  p_id_admin UUID,
  p_id_imagen INTEGER,
  p_texto_alternativo VARCHAR(255) DEFAULT NULL,
  p_es_principal BOOLEAN DEFAULT NULL,
  p_orden_visualizacion INTEGER DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_id_producto UUID;
BEGIN
  -- Obtener ID del producto para validación
  SELECT id_producto INTO v_id_producto
  FROM imagenes_productos
  WHERE id_imagen = p_id_imagen;

  IF v_id_producto IS NULL THEN
    RETURN jsonb_build_object('error', 'Imagen no encontrada');
  END IF;

  -- Si se marca como principal, quitar principal de otras imágenes
  IF p_es_principal = TRUE THEN
    UPDATE imagenes_productos
    SET es_principal = FALSE
    WHERE id_producto = v_id_producto;
  END IF;

  -- Actualizar campos no nulos
  UPDATE imagenes_productos SET
    texto_alternativo = COALESCE(p_texto_alternativo, texto_alternativo),
    es_principal = COALESCE(p_es_principal, es_principal),
    orden_visualizacion = COALESCE(p_orden_visualizacion, orden_visualizacion)
  WHERE id_imagen = p_id_imagen;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Imagen actualizada correctamente',
    'id_imagen', p_id_imagen
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_admin.eliminar_imagen_producto(
  p_id_admin UUID,
  p_id_imagen INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_es_principal BOOLEAN;
  v_id_producto UUID;
BEGIN
  -- Obtener datos de la imagen
  SELECT es_principal, id_producto INTO v_es_principal, v_id_producto
  FROM imagenes_productos
  WHERE id_imagen = p_id_imagen;

  IF v_id_producto IS NULL THEN
    RETURN jsonb_build_object('error', 'Imagen no encontrada');
  END IF;

  -- Eliminar imagen
  DELETE FROM imagenes_productos
  WHERE id_imagen = p_id_imagen;

  -- Si era la imagen principal, asignar nueva principal si hay más imágenes
  IF v_es_principal THEN
    UPDATE imagenes_productos
    SET es_principal = TRUE
    WHERE id_producto = v_id_producto
    AND id_imagen != p_id_imagen
    LIMIT 1;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Imagen eliminada correctamente',
    'id_producto', v_id_producto
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- FUNCIONES DE HISTORIAL Y AUDITORÍA
-- =============================================

CREATE OR REPLACE FUNCTION api_admin.obtener_historial_precios(
  p_id_producto UUID,
  p_pagina INTEGER DEFAULT 1,
  p_por_pagina INTEGER DEFAULT 10
) RETURNS JSONB AS $$
DECLARE
  v_historial JSONB;
  v_total INTEGER;
  v_resultado JSONB;
BEGIN
  -- Contar total de registros
  SELECT COUNT(*) INTO v_total
  FROM historial_precios
  WHERE id_producto = p_id_producto;

  -- Obtener historial paginado
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'fecha', fecha_cambio,
      'precio_anterior', precio_anterior,
      'precio_nuevo', precio_nuevo,
      'diferencia', precio_nuevo - precio_anterior,
      'porcentaje_cambio', ROUND(((precio_nuevo - precio_anterior) / precio_anterior * 100), 2),
      'modificado_por', (
        SELECT nombres || ' ' || apellidos 
        FROM usuarios 
        WHERE id_usuario = hp.modificado_por
      ),
      'razon_cambio', razon_cambio
    )
    ORDER BY fecha_cambio DESC
  ), '[]'::jsonb) INTO v_historial
  FROM historial_precios hp
  WHERE id_producto = p_id_producto
  LIMIT p_por_pagina
  OFFSET (p_pagina - 1) * p_por_pagina;

  -- Construir respuesta con paginación
  SELECT jsonb_build_object(
    'historial', v_historial,
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

CREATE OR REPLACE FUNCTION api_admin.obtener_historial_inventario(
  p_id_producto UUID,
  p_pagina INTEGER DEFAULT 1,
  p_por_pagina INTEGER DEFAULT 10
) RETURNS JSONB AS $$
DECLARE
  v_historial JSONB;
  v_total INTEGER;
  v_resultado JSONB;
BEGIN
  -- Contar total de registros
  SELECT COUNT(*) INTO v_total
  FROM registro_inventario
  WHERE id_producto = p_id_producto;

  -- Obtener historial paginado
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'fecha', fecha_cambio,
      'tipo_cambio', tipo_cambio,
      'cambio_cantidad', cambio_cantidad,
      'nueva_cantidad', nueva_cantidad,
      'modificado_por', (
        SELECT nombres || ' ' || apellidos 
        FROM usuarios 
        WHERE id_usuario = ri.modificado_por
      ),
      'referencia', CASE 
        WHEN tipo_referencia IS NOT NULL THEN jsonb_build_object(
          'tipo', tipo_referencia,
          'id', id_referencia
        )
        ELSE NULL
      END,
      'notas', notas
    )
    ORDER BY fecha_cambio DESC
  ), '[]'::jsonb) INTO v_historial
  FROM registro_inventario ri
  WHERE id_producto = p_id_producto
  LIMIT p_por_pagina
  OFFSET (p_pagina - 1) * p_por_pagina;

  -- Construir respuesta con paginación
  SELECT jsonb_build_object(
    'historial', v_historial,
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

--------------------------------------------------------------
-- Para búsqueda de pedidos
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_creacion);
CREATE INDEX idx_pedidos_estado ON pedidos(id_estado);

-- Para historiales
CREATE INDEX idx_historial_precios_producto ON historial_precios(id_producto, fecha_cambio);
CREATE INDEX idx_inventario_producto ON registro_inventario(id_producto, fecha_cambio);

-- Para productos
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
CREATE POLICY solo_lectura_productos ON productos
  FOR SELECT TO api_admin
  USING (true);

-- Para historiales
ALTER TABLE historial_precios ENABLE ROW LEVEL SECURITY;
CREATE POLICY solo_lectura_historial ON historial_precios
  FOR SELECT TO api_admin
  USING (true);

-- Vistas materializadas para reportes
  CREATE MATERIALIZED VIEW mv_estadisticas_ventas AS
SELECT 
  DATE_TRUNC('month', fecha_creacion) AS mes,
  COUNT(*) AS total_pedidos,
  SUM(total) AS ingresos_totales,
  AVG(total) AS promedio_por_pedido,
  COUNT(DISTINCT id_usuario) AS clientes_unicos
FROM pedidos
GROUP BY DATE_TRUNC('month', fecha_creacion);

CREATE UNIQUE INDEX idx_mv_estadisticas_ventas_mes ON mv_estadisticas_ventas(mes);