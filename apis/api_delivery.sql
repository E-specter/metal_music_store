-- =============================================
-- ESQUEMA API_DELIVERY
-- =============================================

CREATE SCHEMA IF NOT EXISTS api_delivery;

GRANT USAGE ON SCHEMA api_delivery TO api_delivery;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_delivery GRANT EXECUTE ON FUNCTIONS TO api_delivery;

-- Vista segura para repartidores
CREATE VIEW api_delivery.vista_segura_pedidos AS
SELECT 
  p.numero_pedido,
  ep.nombre_estado AS estado,
  p.direccion,
  p.coordenadas,
  u.nombres || ' ' || u.apellidos AS cliente,
  u.telefono
FROM pedidos p
JOIN estados_pedido ep ON p.id_estado = ep.id_estado
JOIN usuarios u ON p.id_usuario = u.id_usuario
WHERE ep.codigo_estado IN ('por_enviar', 'enviado');

-- =============================================
-- FUNCIONES DE GESTIÓN DE PEDIDOS PARA DELIVERY
-- =============================================

CREATE OR REPLACE FUNCTION api_delivery.obtener_pedidos_para_entrega()
RETURNS JSONB AS $$
DECLARE
  v_pedidos JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'numero_pedido', p.numero_pedido,
      'estado', jsonb_build_object(
        'codigo', ep.codigo_estado,
        'nombre', ep.nombre_estado
      ),
      'fecha_creacion', p.fecha_creacion,
      'total', p.total
    )
    ORDER BY 
      CASE WHEN ep.codigo_estado = 'por_enviar' THEN 0 ELSE 1 END,
      p.fecha_creacion
  ), '[]'::jsonb) INTO v_pedidos
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE ep.codigo_estado IN ('por_enviar', 'enviado');

  RETURN jsonb_build_object('pedidos', v_pedidos);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_delivery.actualizar_estado_a_enviado(
  p_id_repartidor UUID,
  p_numero_pedido VARCHAR(50),
  p_notas TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_id_pedido UUID;
  v_estado_actual VARCHAR;
  v_id_estado_enviado INTEGER;
BEGIN
  -- Obtener ID del pedido y estado actual
  SELECT p.id_pedido, ep.codigo_estado INTO v_id_pedido, v_estado_actual
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE p.numero_pedido = p_numero_pedido;

  IF v_id_pedido IS NULL THEN
    RETURN jsonb_build_object('error', 'Pedido no encontrado');
  END IF;

  -- Validar que el estado actual sea "por enviar"
  IF v_estado_actual != 'por_enviar' THEN
    RETURN jsonb_build_object(
      'error', 'Solo se pueden marcar como enviado pedidos en estado "por enviar"',
      'estado_actual', v_estado_actual
    );
  END IF;

  -- Obtener ID del estado "enviado"
  SELECT id_estado INTO v_id_estado_enviado
  FROM estados_pedido
  WHERE codigo_estado = 'enviado';

  -- Actualizar estado del pedido
  UPDATE pedidos
  SET id_estado = v_id_estado_enviado
  WHERE id_pedido = v_id_pedido;

  -- Registrar en historial
  INSERT INTO historial_estados_pedido (
    id_pedido, id_estado, id_usuario, notas
  ) VALUES (
    v_id_pedido, v_id_estado_enviado, p_id_repartidor, 
    COALESCE(p_notas, 'Marcado como enviado por el repartidor')
  );

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Pedido marcado como enviado',
    'numero_pedido', p_numero_pedido,
    'nuevo_estado', 'enviado'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_delivery.obtener_direccion_entrega(
  p_numero_pedido VARCHAR(50)
RETURNS JSONB AS $$
DECLARE
  v_direccion JSONB;
BEGIN
  SELECT jsonb_build_object(
    'direccion', p.direccion,
    'coordenadas', ST_AsGeoJSON(p.coordenadas)::jsonb,
    'instrucciones_entrega', p.notas
  ) INTO v_direccion
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE p.numero_pedido = p_numero_pedido
    AND ep.codigo_estado IN ('por_enviar', 'enviado');

  IF v_direccion IS NULL THEN
    RETURN jsonb_build_object(
      'error', 'Pedido no encontrado o no está en estado válido para entrega',
      'estados_validos', ARRAY['por_enviar', 'enviado']
    );
  END IF;

  RETURN jsonb_build_object('direccion_entrega', v_direccion);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_delivery.obtener_info_contacto_pedido(
  p_numero_pedido VARCHAR(50)
RETURNS JSONB AS $$
DECLARE
  v_contacto JSONB;
BEGIN
  SELECT jsonb_build_object(
    'cliente', jsonb_build_object(
      'nombre_completo', u.nombres || ' ' || u.apellidos,
      'telefono', u.telefono,
      'correo', u.correo_electronico
    ),
    'remitente', p.informacion_remitente
  ) INTO v_contacto
  FROM pedidos p
  JOIN usuarios u ON p.id_usuario = u.id_usuario
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE p.numero_pedido = p_numero_pedido
    AND ep.codigo_estado IN ('por_enviar', 'enviado');

  IF v_contacto IS NULL THEN
    RETURN jsonb_build_object(
      'error', 'Pedido no encontrado o no está en estado válido para entrega',
      'estados_validos', ARRAY['por_enviar', 'enviado']
    );
  END IF;

  RETURN jsonb_build_object('contacto', v_contacto);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION api_delivery.obtener_detalle_pedido_entrega(
  p_numero_pedido VARCHAR(50)
RETURNS JSONB AS $$
DECLARE
  v_pedido JSONB;
BEGIN
  SELECT jsonb_build_object(
    'numero_pedido', p.numero_pedido,
    'fecha_creacion', p.fecha_creacion,
    'estado', jsonb_build_object(
      'codigo', ep.codigo_estado,
      'nombre', ep.nombre_estado
    ),
    'direccion_entrega', jsonb_build_object(
      'direccion', p.direccion,
      'coordenadas', ST_AsGeoJSON(p.coordenadas)::jsonb,
      'instrucciones', p.notas
    ),
    'contacto', jsonb_build_object(
      'cliente', jsonb_build_object(
        'nombre', u.nombres || ' ' || u.apellidos,
        'telefono', u.telefono
      ),
      'remitente', p.informacion_remitente
    ),
    'items', (
      SELECT jsonb_agg(jsonb_build_object(
        'nombre', pr.nombre,
        'cantidad', ip.cantidad
      ))
      FROM items_pedido ip
      JOIN productos pr ON ip.id_producto = pr.id_producto
      WHERE ip.id_pedido = p.id_pedido
    ),
    'total', p.total
  ) INTO v_pedido
  FROM pedidos p
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  JOIN usuarios u ON p.id_usuario = u.id_usuario
  WHERE p.numero_pedido = p_numero_pedido
    AND ep.codigo_estado IN ('por_enviar', 'enviado');

  IF v_pedido IS NULL THEN
    RETURN jsonb_build_object(
      'error', 'Pedido no encontrado o no está en estado válido para entrega',
      'estados_validos', ARRAY['por_enviar', 'enviado']
    );
  END IF;

  RETURN jsonb_build_object('pedido', v_pedido);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
--------------------------------------------------------------
-- Calcular ruta óptima para entrega
CREATE OR REPLACE FUNCTION api_delivery.calcular_ruta_entrega(
  p_punto_actual GEOMETRY(POINT, 4326),
  p_limite INTEGER DEFAULT 10
) RETURNS JSONB AS $$
DECLARE
  v_ruta JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'numero_pedido', p.numero_pedido,
      'distancia_km', ROUND(ST_Distance(
        p.coordenadas::geography,
        p_punto_actual::geography
      ) / 1000, 2),
      'direccion', p.direccion->>'linea1',
      'cliente', u.nombres || ' ' || u.apellidos
    )
    ORDER BY ST_Distance(p.coordenadas::geography, p_punto_actual::geography)
    LIMIT p_limite
  ), '[]'::jsonb) INTO v_ruta
  FROM pedidos p
  JOIN usuarios u ON p.id_usuario = u.id_usuario
  JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE ep.codigo_estado = 'por_enviar';

  RETURN jsonb_build_object('ruta_optimizada', v_ruta);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

--------------------------------------------------------------
-- Para búsqueda rápida por número de pedido
CREATE INDEX idx_pedidos_numero ON pedidos(numero_pedido);

-- Para filtrado por estado
CREATE INDEX idx_pedidos_estado ON pedidos(id_estado) 
WHERE id_estado IN (
  SELECT id_estado FROM estados_pedido 
  WHERE codigo_estado IN ('por_enviar', 'enviado')
);


ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
CREATE POLICY pedidos_para_entrega ON pedidos
  FOR SELECT TO api_delivery
  USING (id_estado IN (
    SELECT id_estado FROM estados_pedido 
    WHERE codigo_estado IN ('por_enviar', 'enviado')
  ));


CREATE VIEW vista_pedidos_para_entrega AS
SELECT 
  p.numero_pedido,
  ep.nombre_estado AS estado,
  p.direccion,
  p.coordenadas,
  u.nombres || ' ' || u.apellidos AS cliente,
  u.telefono,
  p.informacion_remitente,
  p.notas AS instrucciones_entrega
FROM pedidos p
JOIN estados_pedido ep ON p.id_estado = ep.id_estado
JOIN usuarios u ON p.id_usuario = u.id_usuario
WHERE ep.codigo_estado IN ('por_enviar', 'enviado');