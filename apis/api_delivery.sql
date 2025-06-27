-- Pedidos pendientes de envío
CREATE FUNCTION api_delivery.pedidos_pendientes() RETURNS TABLE (
  pedido_id INT,
  numero_pedido VARCHAR,
  cliente VARCHAR,
  direccion_envio TEXT,
  fecha_creacion TIMESTAMP
) AS $$ BEGIN RETURN QUERY
SELECT p.id_pedido,
  p.numero_pedido,
  u.nombre_usuario AS cliente,
  (
    SELECT direccion_linea1 || ', ' || ciudad
    FROM direcciones_pedido
    WHERE id_pedido = p.id_pedido
      AND tipo_direccion = 'envio'
  ) AS direccion,
  p.fecha_creacion
FROM pedidos p
  JOIN usuarios u ON p.id_usuario = u.id_usuario
WHERE p.id_estado = 3;
-- Estado: Listo para envío
END;
$$ LANGUAGE plpgsql;
-- Actualizar estado de envío
CREATE PROCEDURE api_delivery.actualizar_estado_envio(
  _pedido_id INT,
  _nuevo_estado VARCHAR,
  _notas TEXT DEFAULT ''
) AS $$
DECLARE _estado_id INT;
BEGIN
SELECT id_estado INTO _estado_id
FROM estados_pedido
WHERE codigo_estado = _nuevo_estado;
UPDATE pedidos
SET id_estado = _estado_id
WHERE id_pedido = _pedido_id;
INSERT INTO historial_estados_pedido (id_pedido, id_estado, notas)
VALUES (_pedido_id, _estado_id, _notas);
END;
$$ LANGUAGE plpgsql;

-- Generar ruta de entrega
CREATE FUNCTION api_delivery.generar_ruta_entrega(_fecha DATE)
RETURNS TABLE (
    pedido_id INT,
    secuencia INT,
    direccion TEXT,
    latitud DECIMAL,
    longitud DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    WITH pedidos_dia AS (
        SELECT p.id_pedido, u.latitud, u.longitud
        FROM pedidos p
        JOIN direcciones_pedido dp ON p.id_pedido = dp.id_pedido
        JOIN ubicaciones u ON dp.id_ubicacion = u.id_ubicacion
        WHERE DATE(p.fecha_creacion) = _fecha
          AND p.id_estado = 3 -- Estado "Para entrega"
    )
    SELECT id_pedido,
          ROW_NUMBER() OVER (ORDER BY latitud, longitud) AS secuencia,
          (SELECT direccion_linea1 || ', ' || ciudad FROM ubicaciones WHERE id_ubicacion = dp.id_ubicacion),
          latitud,
          longitud
    FROM pedidos_dia
    ORDER BY secuencia;
END;
$$ LANGUAGE plpgsql;