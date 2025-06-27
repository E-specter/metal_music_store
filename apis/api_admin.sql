-- Crear categoría
CREATE PROCEDURE api_admin.crear_categoria(
    _nombre VARCHAR(100),
    _id_padre INT DEFAULT NULL
) AS $$
BEGIN
    INSERT INTO categorias(nombre, id_categoria_padre, slug)
    VALUES (_nombre, _id_padre, lower(replace(_nombre, ' ', '-')));
END;
$$ LANGUAGE plpgsql;

-- Actualizar producto
CREATE PROCEDURE api_admin.actualizar_producto(
    _producto_id INT,
    _precio DECIMAL DEFAULT NULL,
    _stock INT DEFAULT NULL,
    _activo BOOLEAN DEFAULT NULL
) AS $$
BEGIN
    UPDATE productos
    SET 
        precio = COALESCE(_precio, precio),
        cantidad_disponible = COALESCE(_stock, cantidad_disponible),
        esta_activo = COALESCE(_activo, esta_activo)
    WHERE id_producto = _producto_id;
END;
$$ LANGUAGE plpgsql;

-- Reabastecer inventario
CREATE PROCEDURE api_admin.reabastecer_inventario(
    _umbral_min INT = 10,
    _cantidad_reabastecer INT = 50
) AS $$
BEGIN
    UPDATE productos
    SET cantidad_disponible = cantidad_disponible + _cantidad_reabastecer
    WHERE cantidad_disponible < _umbral_min;
    
    INSERT INTO registro_inventario(id_producto, cambio_cantidad, nueva_cantidad, tipo_cambio)
    SELECT id_producto, _cantidad_reabastecer, cantidad_disponible + _cantidad_reabastecer, 'reabastecimiento'
    FROM productos
    WHERE cantidad_disponible < _umbral_min;
END;
$$ LANGUAGE plpgsql;

-- Actualización masiva de inventario
CREATE PROCEDURE api_admin.actualizar_inventario(_productos JSONB) AS $$
DECLARE _producto JSONB;
BEGIN FOR _producto IN
SELECT *
FROM jsonb_array_elements(_productos) LOOP
UPDATE productos
SET cantidad_disponible = (_producto->>'cantidad')::INT,
  fecha_actualizacion = NOW()
WHERE id_producto = (_producto->>'id')::INT;
INSERT INTO registro_inventario (
    id_producto,
    cambio_cantidad,
    nueva_cantidad,
    tipo_cambio,
    notas
  )
VALUES (
    (_producto->>'id')::INT,
    (_producto->>'cantidad')::INT - cantidad_disponible,
    (_producto->>'cantidad')::INT,
    'ajuste',
    'Actualización masiva'
  );
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Reporte de ventas con filtros avanzados
CREATE FUNCTION api_admin.reporte_ventas(
  _desde DATE DEFAULT NOW() - INTERVAL '30 days',
  _hasta DATE DEFAULT NOW(),
  _categoria_id INT DEFAULT NULL
) RETURNS TABLE (
  producto VARCHAR,
  categoria VARCHAR,
  unidades_vendidas BIGINT,
  ingresos_totales DECIMAL
) AS $$ BEGIN RETURN QUERY
SELECT p.nombre AS producto,
  c.nombre AS categoria,
  SUM(ip.cantidad) AS unidades_vendidas,
  SUM(ip.precio_total) AS ingresos_totales
FROM items_pedido ip
  JOIN productos p ON ip.id_producto = p.id_producto
  JOIN categorias c ON p.id_categoria = c.id_categoria
  JOIN pedidos ped ON ip.id_pedido = ped.id_pedido
WHERE ped.fecha_creacion BETWEEN _desde AND _hasta
  AND (
    _categoria_id IS NULL
    OR c.id_categoria = _categoria_id
  )
GROUP BY p.nombre,
  c.nombre
ORDER BY ingresos_totales DESC;
END;
$$ LANGUAGE plpgsql;

-- Dashboard de métricas clave
CREATE FUNCTION api_admin.metricas_dashboard() RETURNS JSONB AS $$
DECLARE resultado JSONB;
BEGIN
SELECT jsonb_build_object(
    'ventas_mes',
    (
      SELECT SUM(total)
      FROM pedidos
      WHERE fecha_creacion >= DATE_TRUNC('month', NOW())
    ),
    'productos_bajo_stock',
    (
      SELECT COUNT(*)
      FROM inventario_bajo
    ),
    'pedidos_pendientes',
    (
      SELECT COUNT(*)
      FROM pedidos
      WHERE id_estado IN (1, 2)
    ),
    -- Estados: Pendiente/Procesando
    'mejores_productos',
    (
      SELECT jsonb_agg(
          jsonb_build_object(
            'producto',
            nombre,
            'ventas',
            total_vendido
          )
          FROM productos_populares
          LIMIT 5
        )
    ) INTO resultado;
RETURN resultado;
END;
$$ LANGUAGE plpgsql;

-- Análisis de tendencias de productos
CREATE FUNCTION api_admin.analisis_tendencias(
    _meses_historial INT = 6
) RETURNS TABLE (
    categoria VARCHAR,
    crecimiento DECIMAL,
    productos_populares JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH datos_historicos AS (
        -- Cálculo complejo de tendencias
    )
    SELECT * FROM datos_historicos;
END;
$$ LANGUAGE plpgsql;

-- Obtener clientes VIP
CREATE FUNCTION api_admin.obtener_clientes_vip(
    _limite INT = 10,
    _periodo INTERVAL = '1 year'
) RETURNS TABLE (
    usuario_id INT,
    nombre_completo TEXT,
    total_gastado DECIMAL,
    pedidos_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT u.id_usuario, 
          u.nombres || ' ' || u.apellidos,
          SUM(p.total) AS total_gastado,
          COUNT(*) AS pedidos_count
    FROM usuarios u
    JOIN pedidos p ON u.id_usuario = p.id_usuario
    WHERE p.fecha_creacion > NOW() - _periodo
    GROUP BY u.id_usuario
    ORDER BY total_gastado DESC
    LIMIT _limite;
END;
$$ LANGUAGE plpgsql;

-- Archivar pedidos antiguos
CREATE PROCEDURE api_admin.archivar_pedidos_antiguos(
    _anios_retencion INT = 2
) AS $$
BEGIN
    -- Mover pedidos antiguos a tabla de archivado
    INSERT INTO pedidos_archivado
    SELECT * FROM pedidos
    WHERE fecha_creacion < NOW() - (_anios_retencion * INTERVAL '1 year');
    
    -- Eliminar de tabla principal
    DELETE FROM pedidos
    WHERE fecha_creacion < NOW() - (_anios_retencion * INTERVAL '1 year');
END;
$$ LANGUAGE plpgsql;

CREATE PROCEDURE api_admin.ejecutar_mantenimiento_nocturno() AS $$
BEGIN
    VACUUM ANALYZE;
    REINDEX DATABASE metal_music_store;
    REFRESH MATERIALIZED VIEW CONCURRENTLY reporte_ventas_mensual;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------
-- Rotar credenciales de usuario
CREATE PROCEDURE api_admin.rotar_credenciales_usuario(
    _usuario_id INT
) AS $$
DECLARE
    nueva_contrasena TEXT;
BEGIN
    nueva_contrasena := substr(md5(random()::text), 0, 12);
    
    UPDATE usuarios
    SET contrasena_hash = crypt(nueva_contrasena, gen_salt('bf'))
    WHERE id_usuario = _usuario_id;
    
    -- Lógica para notificar al usuario (implementar fuera de DB)
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------
-- Auditoría de accesos
CREATE FUNCTION api_admin.auditar_accesos_usuario(
    _usuario_id INT,
    _desde TIMESTAMP DEFAULT NOW() - INTERVAL '30 days'
) RETURNS TABLE (
    fecha_acceso TIMESTAMP,
    direccion_ip INET,
    user_agent TEXT
) AS $$
BEGIN
    -- Implementar usando tabla de auditoría (no incluida en diseño inicial)
    RETURN QUERY
    SELECT fecha_acceso, direccion_ip, user_agent
    FROM auditoria_accesos
    WHERE id_usuario = _usuario_id
      AND fecha_acceso >= _desde;
END;
$$ LANGUAGE plpgsql;