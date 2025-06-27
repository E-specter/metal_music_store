-- Productos visibles con paginación
CREATE FUNCTION api_public.registrar_usuario(
    _nombre_usuario VARCHAR(50),
    _correo VARCHAR(255),
    _contrasena TEXT,
    _nombres VARCHAR(100),
    _apellidos VARCHAR(100)
) RETURNS INT AS $$
DECLARE user_id INT;
BEGIN
    INSERT INTO usuarios(nombre_usuario, correo_electronico, contrasena_hash, nombres, apellidos, id_rol)
    VALUES (_nombre_usuario, _correo, crypt(_contrasena, gen_salt('bf')), _nombres, _apellidos, 2) -- Rol 2 = Cliente
    RETURNING id_usuario INTO user_id;
    
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Autenticar usuario
CREATE FUNCTION api_public.autenticar_usuario(
    _identificador VARCHAR(255), -- Puede ser email o nombre de usuario
    _contrasena TEXT
) RETURNS TABLE (id_usuario INT, rol VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT u.id_usuario, r.nombre_rol
    FROM usuarios u
    JOIN roles r ON u.id_rol = r.id_rol
    WHERE (u.correo_electronico = _identificador OR u.nombre_usuario = _identificador)
      AND u.contrasena_hash = crypt(_contrasena, u.contrasena_hash);
END;
$$ LANGUAGE plpgsql;

-- Productos visibles con paginación
CREATE FUNCTION api_public.obtener_productos(_pagina INT = 1, _por_pagina INT = 20) RETURNS TABLE (
  id_producto INT,
  nombre VARCHAR,
  precio DECIMAL,
  url_imagen VARCHAR,
  calificacion_promedio NUMERIC
) AS $$ BEGIN RETURN QUERY
SELECT p.id_producto,
  p.nombre,
  p.precio,
  ip.url_imagen,
  ROUND(AVG(r.calificacion), 1) AS calificacion_promedio
FROM productos p
  LEFT JOIN imagenes_productos ip ON p.id_producto = ip.id_producto
  AND ip.es_principal
  LEFT JOIN reseñas_productos r ON p.id_producto = r.id_producto
WHERE p.esta_activo
GROUP BY p.id_producto,
  ip.url_imagen
ORDER BY p.fecha_creacion DESC
LIMIT _por_pagina OFFSET (_pagina - 1) * _por_pagina;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Búsqueda de productos con filtros
CREATE FUNCTION api_public.buscar_productos(
  _termino VARCHAR,
  _categoria_id INT DEFAULT NULL
) RETURNS TABLE (id INT, nombre VARCHAR, slug_categoria VARCHAR) AS $$ BEGIN RETURN QUERY
SELECT p.id_producto,
  p.nombre,
  c.slug
FROM productos p
  JOIN categorias c ON p.id_categoria = c.id_categoria
WHERE (
    p.nombre ILIKE '%' || _termino || '%'
    OR p.descripcion ILIKE '%' || _termino || '%'
  )
  AND (
    _categoria_id IS NULL
    OR c.id_categoria = _categoria_id
  )
  AND p.esta_activo;
END;
$$ LANGUAGE plpgsql;

-- Detalle de producto con imágenes y reseñas
CREATE FUNCTION api_public.detalle_producto(_producto_id INT) RETURNS JSONB AS $$
DECLARE resultado JSONB;
BEGIN
SELECT jsonb_build_object(
    'producto',
    jsonb_build_object(
      'id',
      p.id_producto,
      'nombre',
      p.nombre,
      'descripcion',
      p.descripcion,
      'precio',
      p.precio,
      'especificaciones',
      dt.especificaciones
    ),
    'imagenes',
    COALESCE(
      (
        SELECT jsonb_agg(
            jsonb_build_object('url', url_imagen, 'alt', texto_alternativo)
          )
        FROM imagenes_productos
        WHERE id_producto = p.id_producto,
          '[]'
      ),
      'reseñas',
      COALESCE(
        (
          SELECT jsonb_agg(
              jsonb_build_object(
                'usuario',
                u.nombre_usuario,
                'calificacion',
                r.calificacion
              )
            )
          FROM reseñas_productos r
            JOIN usuarios u ON r.id_usuario = u.id_usuario
          WHERE r.id_producto = p.id_producto
            AND r.esta_aprobada,
            '[]'
        )
      ) INTO resultado
      FROM productos p
        JOIN detalles_tecnicos_productos dt ON p.id_detalle_tecnico = dt.id_detalle_tecnico
      WHERE p.id_producto = _producto_id;
RETURN resultado;
END;
$$ LANGUAGE plpgsql;