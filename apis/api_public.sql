-- =============================================
-- ESQUEMA API_PUBLIC
-- =============================================
CREATE SCHEMA IF NOT EXISTS api_public;
GRANT USAGE ON SCHEMA api_public TO api_public;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_public
GRANT EXECUTE ON FUNCTIONS TO api_public;

-- =============================================
-- FUNCIONES DE AUTENTICACIÓN
-- =============================================

-- Verificar rol del usuario: Verifica si el usuario tiene el rol requerido
CREATE OR REPLACE FUNCTION public.verificar_rol_usuario(
  p_user_id UUID,
  p_required_role VARCHAR
) RETURNS BOOLEAN AS $$
DECLARE
  v_user_role VARCHAR;
BEGIN
  SELECT r.nombre_rol INTO v_user_role
  FROM usuarios u
  JOIN roles r ON u.id_rol = r.id_rol
  WHERE u.id_usuario = p_user_id;

  IF v_user_role = p_required_role THEN
    RETURN TRUE;
  END IF;

  -- Admins tienen acceso a api_customer también
  IF p_required_role = 'customer' AND v_user_role = 'admin' THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.set_current_user_context()
RETURNS TRIGGER AS $$
BEGIN
  -- Verificar JWT y establecer contexto
  -- Esta función sería llamada por Supabase Auth hooks
  EXECUTE format('SET app.current_user_id = %L', NEW.id);
  EXECUTE format('SET app.current_user_role = %L', NEW.role);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Validar contraseña: debe tener al menos 8 caracteres, una mayúscula, un número y un caracter especial
CREATE OR REPLACE FUNCTION public.validar_contrasena(p_contrasena TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Al menos 8 caracteres
  IF length(p_contrasena) < 8 THEN
    RETURN FALSE;
  END IF;
  
  -- Al menos una mayúscula
  IF p_contrasena !~ '[A-Z]' THEN
    RETURN FALSE;
  END IF;
  
  -- Al menos un número
  IF p_contrasena !~ '[0-9]' THEN
    RETURN FALSE;
  END IF;
  
  -- Al menos un caracter especial
  IF p_contrasena !~ '[^a-zA-Z0-9]' THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Registrar usuario: debe validar que el correo sea válido, el teléfono peruano y que la contraseña sea válida
CREATE OR REPLACE FUNCTION api_public.registrar_usuario(
    p_nombre_usuario VARCHAR(50),
    p_correo VARCHAR(255),
    p_contrasena TEXT,
    p_nombres VARCHAR(100),
    p_apellidos VARCHAR(100),
    p_telefono VARCHAR(20) RETURNS JSONB AS $$
    DECLARE v_id_usuario UUID;
v_resultado JSONB;
BEGIN -- Validar formato de correo
IF p_correo !~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' THEN RETURN jsonb_build_object(
  'error',
  'Formato de correo electrónico inválido'
);
END IF;
-- Validar formato de teléfono peruano
IF p_telefono IS NOT NULL
AND p_telefono !~ '^9[0-9]{8}$' THEN RETURN jsonb_build_object(
  'error',
  'Teléfono debe ser un número peruano de 9 dígitos comenzando con 9'
);
END IF;
INSERT INTO usuarios(
    nombre_usuario,
    correo_electronico,
    contrasena_hash,
    nombres,
    apellidos,
    telefono,
    id_rol
  )
VALUES (
    p_nombre_usuario,
    p_correo,
    crypt(p_contrasena, gen_salt('bf')),
    p_nombres,
    p_apellidos,
    p_telefono,
    (
      SELECT id_rol
      FROM roles
      WHERE nombre_rol = 'customer'
    )
    RETURNING id_usuario INTO v_id_usuario;
-- Retornar información básica del usuario registrado
SELECT jsonb_build_object(
    'id_usuario',
    v_id_usuario,
    'nombre_usuario',
    p_nombre_usuario,
    'nombres',
    p_nombres,
    'apellidos',
    p_apellidos,
    'correo',
    p_correo,
    'telefono',
    p_telefono,
    'mensaje',
    'Usuario registrado exitosamente'
  ) INTO v_resultado;
RETURN v_resultado;
EXCEPTION
WHEN unique_violation THEN RETURN jsonb_build_object(
  'error',
  'El nombre de usuario o correo electrónico ya está en uso'
);
WHEN others THEN RETURN jsonb_build_object('error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION api_public.iniciar_sesion(
    p_identificador VARCHAR(255),
    p_contrasena TEXT
  ) RETURNS JSONB AS $$
DECLARE v_usuario JSONB;
BEGIN
SELECT jsonb_build_object(
    'id_usuario',
    u.id_usuario,
    'nombre_usuario',
    u.nombre_usuario,
    'nombres',
    u.nombres,
    'apellidos',
    u.apellidos,
    'correo',
    u.correo_electronico,
    'rol',
    r.nombre_rol,
    'esta_activo',
    u.esta_activo
  ) INTO v_usuario
FROM usuarios u
  JOIN roles r ON u.id_rol = r.id_rol
WHERE (
    u.nombre_usuario = p_identificador
    OR u.correo_electronico = p_identificador
  )
  AND u.contrasena_hash = crypt(p_contrasena, u.contrasena_hash)
  AND u.esta_activo;
IF v_usuario IS NULL THEN RETURN jsonb_build_object(
  'error',
  'Credenciales inválidas o usuario inactivo'
);
END IF;
RETURN jsonb_build_object(
  'success',
  true,
  'data',
  v_usuario
);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- =============================================
-- FUNCIONES DE CATALOGO DE PRODUCTOS
-- =============================================
CREATE OR REPLACE FUNCTION api_public.obtener_categorias() RETURNS JSONB AS $$
DECLARE v_categorias JSONB;
BEGIN WITH RECURSIVE categorias_tree AS (
  SELECT id_categoria,
    nombre,
    descripcion,
    id_categoria_padre,
    jsonb_build_array()::jsonb AS subcategorias
  FROM categorias
  WHERE id_categoria_padre IS NULL
    AND esta_activo
  UNION ALL
  SELECT c.id_categoria,
    c.nombre,
    c.descripcion,
    c.id_categoria_padre,
    jsonb_build_array()::jsonb
  FROM categorias c
    JOIN categorias_tree ct ON c.id_categoria_padre = ct.id_categoria
  WHERE c.esta_activo
)
SELECT jsonb_agg(
    jsonb_build_object(
      'id',
      id_categoria,
      'nombre',
      nombre,
      'descripcion',
      descripcion,
      'subcategorias',
      subcategorias
    )
  ) INTO v_categorias
FROM categorias_tree
WHERE id_categoria_padre IS NULL;
RETURN jsonb_build_object(
  'categorias',
  COALESCE(v_categorias, '[]'::jsonb)
);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION api_public.buscar_productos(
    p_termino_busqueda VARCHAR DEFAULT NULL,
    p_id_categoria INTEGER DEFAULT NULL,
    p_rango_precio NUMERIC [] DEFAULT NULL,
    p_pagina INTEGER DEFAULT 1,
    p_por_pagina INTEGER DEFAULT 20,
    p_orden VARCHAR DEFAULT 'recientes'
  ) RETURNS JSONB AS $$
DECLARE v_productos JSONB;
v_total INTEGER;
v_resultado JSONB;
BEGIN -- Contar total de productos que coinciden con los filtros
SELECT COUNT(*) INTO v_total
FROM productos p
  JOIN categorias c ON p.id_categoria = c.id_categoria
WHERE p.esta_activo
  AND (
    p_termino_busqueda IS NULL
    OR (
      p.nombre ILIKE '%' || p_termino_busqueda || '%'
      OR p.descripcion ILIKE '%' || p_termino_busqueda || '%'
    )
  )
  AND (
    p_id_categoria IS NULL
    OR p.id_categoria = p_id_categoria
    OR c.id_categoria_padre = p_id_categoria
  )
  AND (
    p_rango_precio IS NULL
    OR (
      p.precio BETWEEN p_rango_precio [1] AND p_rango_precio [2]
    )
  );
-- Obtener productos paginados
SELECT jsonb_agg(
    jsonb_build_object(
      'id',
      p.id_producto,
      'nombre',
      p.nombre,
      'precio',
      p.precio,
      'imagen_principal',
      (
        SELECT url_imagen
        FROM imagenes_productos
        WHERE id_producto = p.id_producto
          AND es_principal
        LIMIT 1
      ), 'calificacion_promedio', (
        SELECT COALESCE(AVG(calificacion), 0)
        FROM resenas_productos
        WHERE id_producto = p.id_producto
          AND esta_aprobado
      ),
      'marca',
      p.marca
    )
  ) INTO v_productos
FROM productos p
  JOIN categorias c ON p.id_categoria = c.id_categoria
WHERE p.esta_activo
  AND (
    p_termino_busqueda IS NULL
    OR (
      p.nombre ILIKE '%' || p_termino_busqueda || '%'
      OR p.descripcion ILIKE '%' || p_termino_busqueda || '%'
    )
  )
  AND (
    p_id_categoria IS NULL
    OR p.id_categoria = p_id_categoria
    OR c.id_categoria_padre = p_id_categoria
  )
  AND (
    p_rango_precio IS NULL
    OR (
      p.precio BETWEEN p_rango_precio [1] AND p_rango_precio [2]
    )
  )
ORDER BY CASE
    p_orden
    WHEN 'recientes' THEN p.fecha_creacion
    WHEN 'precio_asc' THEN p.precio
    WHEN 'precio_desc' THEN - p.precio
    WHEN 'mejor_calificados' THEN (
      SELECT - COALESCE(AVG(calificacion), 0)
      FROM resenas_productos
      WHERE id_producto = p.id_producto
        AND esta_aprobado
    )
    ELSE p.fecha_creacion
  END DESC
LIMIT p_por_pagina OFFSET (p_pagina - 1) * p_por_pagina;
-- Construir respuesta con paginación
SELECT jsonb_build_object(
    'productos',
    COALESCE(v_productos, '[]'::jsonb),
    'paginacion',
    jsonb_build_object(
      'pagina_actual',
      p_pagina,
      'por_pagina',
      p_por_pagina,
      'total',
      v_total,
      'total_paginas',
      CEIL(v_total::FLOAT / p_por_pagina)
    )
  ) INTO v_resultado;
RETURN v_resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION api_public.obtener_detalle_producto(p_id_producto UUID) RETURNS JSONB AS $$
DECLARE v_producto JSONB;
v_imagenes JSONB;
v_resenas JSONB;
v_resultado JSONB;
BEGIN -- Obtener información básica del producto
SELECT jsonb_build_object(
    'id',
    p.id_producto,
    'nombre',
    p.nombre,
    'descripcion',
    p.descripcion,
    'precio',
    p.precio,
    'costo',
    p.costo,
    'disponibilidad',
    p.cantidad_disponible,
    'marca',
    p.marca,
    'talla',
    p.talla,
    'categoria',
    jsonb_build_object(
      'id',
      c.id_categoria,
      'nombre',
      c.nombre
    ),
    'detalles_tecnicos',
    jsonb_build_object(
      'peso',
      dp.peso,
      'dimensiones',
      dp.dimensiones,
      'material_principal',
      dp.material_principal,
      'materiales_secundarios',
      dp.materiales_secundarios,
      'cuidados_especiales',
      dp.cuidados_especiales,
      'especificaciones',
      dp.especificaciones
    ),
    'atributos',
    p.atributos_generales
  ) INTO v_producto
FROM productos p
  JOIN categorias c ON p.id_categoria = c.id_categoria
  JOIN detalles_productos dp ON p.id_detalle_producto = dp.id_detalle_producto
WHERE p.id_producto = p_id_producto
  AND p.esta_activo;
IF v_producto IS NULL THEN RETURN jsonb_build_object('error', 'Producto no encontrado o inactivo');
END IF;
-- Obtener imágenes del producto
SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'url',
        url_imagen,
        'texto_alternativo',
        texto_alternativo,
        'es_principal',
        es_principal,
        'orden',
        orden_visualizacion
      )
      ORDER BY orden_visualizacion
    ),
    '[]'::jsonb
  ) INTO v_imagenes
FROM imagenes_productos
WHERE id_producto = p_id_producto;
-- Obtener reseñas aprobadas
SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id',
        r.id_resena,
        'usuario',
        jsonb_build_object(
          'nombre',
          u.nombres,
          'apellido',
          u.apellidos
        ),
        'calificacion',
        r.calificacion,
        'comentario',
        r.comentario,
        'fecha',
        r.fecha_creacion
      )
      ORDER BY r.fecha_creacion DESC
    ),
    '[]'::jsonb
  ) INTO v_resenas
FROM resenas_productos r
  JOIN usuarios u ON r.id_usuario = u.id_usuario
WHERE r.id_producto = p_id_producto
  AND r.esta_aprobado;
-- Calcular promedio de calificaciones
SELECT COALESCE(AVG(calificacion), 0) INTO v_resultado
FROM resenas_productos
WHERE id_producto = p_id_producto
  AND esta_aprobado;
-- Construir respuesta final
SELECT jsonb_build_object(
    'producto',
    v_producto,
    'imagenes',
    v_imagenes,
    'resenas',
    v_resenas,
    'calificacion_promedio',
    v_resultado
  ) INTO v_resultado;
RETURN v_resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- =============================================
-- FUNCIONES DE OFERTAS Y PROMOCIONES
-- =============================================
CREATE OR REPLACE FUNCTION api_public.obtener_ofertas(p_limit INTEGER DEFAULT 10) RETURNS JSONB AS $$
DECLARE v_ofertas JSONB;
BEGIN
SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id',
        p.id_producto,
        'nombre',
        p.nombre,
        'precio_original',
        p.precio,
        'precio_oferta',
        (p.precio * 0.9),
        -- Ejemplo: 10% de descuento
        'imagen',
        (
          SELECT url_imagen
          FROM imagenes_productos
          WHERE id_producto = p.id_producto
            AND es_principal
          LIMIT 1
        ), 'valido_hasta', (CURRENT_DATE + INTERVAL '7 days') -- Oferta válida por 7 días
      )
      ORDER BY p.fecha_creacion DESC
      LIMIT p_limit
    ), '[]'::jsonb
  ) INTO v_ofertas
FROM productos p
WHERE p.esta_activo
  AND p.cantidad_disponible > 0;
RETURN jsonb_build_object('ofertas', v_ofertas);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION api_public.obtener_promociones() RETURNS JSONB AS $$
DECLARE v_promociones JSONB;
BEGIN -- Ejemplo de promociones (en un sistema real podrían venir de una tabla específica)
SELECT jsonb_build_array(
    jsonb_build_object(
      'id',
      1,
      'titulo',
      'Envío gratis',
      'descripcion',
      'Envío gratis en compras mayores a S/100',
      'valido_hasta',
      (CURRENT_DATE + INTERVAL '30 days'),
      'imagen',
      'https://ejemplo.com/promo-envio-gratis.jpg'
    ),
    jsonb_build_object(
      'id',
      2,
      'titulo',
      '2x1 en productos seleccionados',
      'descripcion',
      'Lleva 2 productos por el precio de 1 en la sección de ofertas',
      'valido_hasta',
      (CURRENT_DATE + INTERVAL '15 days'),
      'imagen',
      'https://ejemplo.com/promo-2x1.jpg'
    )
  ) INTO v_promociones;
RETURN jsonb_build_object('promociones', v_promociones);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- =============================================
-- FUNCIONES DE RESEÑAS
-- =============================================
CREATE OR REPLACE FUNCTION api_public.obtener_resenas_producto(
    p_id_producto UUID,
    p_pagina INTEGER DEFAULT 1,
    p_por_pagina INTEGER DEFAULT 5
  ) RETURNS JSONB AS $$
DECLARE v_resenas JSONB;
v_total INTEGER;
v_resultado JSONB;
BEGIN -- Contar total de reseñas
SELECT COUNT(*) INTO v_total
FROM resenas_productos
WHERE id_producto = p_id_producto
  AND esta_aprobado;
-- Obtener reseñas paginadas
SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id',
        r.id_resena,
        'usuario',
        jsonb_build_object(
          'nombre',
          u.nombres,
          'iniciales',
          SUBSTRING(
            u.nombres
            FROM 1 FOR 1
          ) || SUBSTRING(
            u.apellidos
            FROM 1 FOR 1
          )
        ),
        'calificacion',
        r.calificacion,
        'comentario',
        r.comentario,
        'fecha',
        TO_CHAR(r.fecha_creacion, 'DD/MM/YYYY')
      )
    ),
    '[]'::jsonb
  ) INTO v_resenas
FROM resenas_productos r
  JOIN usuarios u ON r.id_usuario = u.id_usuario
WHERE r.id_producto = p_id_producto
  AND r.esta_aprobado
ORDER BY r.fecha_creacion DESC
LIMIT p_por_pagina OFFSET (p_pagina - 1) * p_por_pagina;
-- Construir respuesta con paginación
SELECT jsonb_build_object(
    'resenas',
    v_resenas,
    'paginacion',
    jsonb_build_object(
      'pagina_actual',
      p_pagina,
      'por_pagina',
      p_por_pagina,
      'total',
      v_total,
      'total_paginas',
      CEIL(v_total::FLOAT / p_por_pagina)
    )
  ) INTO v_resultado;
RETURN v_resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

---------------------------------------------------------------
-- Para búsqueda de productos
CREATE INDEX idx_productos_busqueda ON productos USING gin(to_tsvector('spanish', nombre || ' ' || descripcion));
CREATE INDEX idx_productos_activos ON productos(id_producto) WHERE esta_activo;

-- Para búsqueda geográfica
CREATE INDEX idx_ubicaciones_geo ON ubicaciones USING gist(coordenadas);

-- Para autenticación
CREATE INDEX idx_usuarios_auth ON usuarios(nombre_usuario, correo_electronico) WHERE esta_activo;

ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
CREATE POLICY productos_publicos ON productos
  FOR SELECT TO api_public
  USING (esta_activo);