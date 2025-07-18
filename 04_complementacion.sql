-- Cleaned SQL Indices and Views for metal_music_store

-- INDICES (Remove Duplicates)
CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos(id_categoria);
CREATE INDEX IF NOT EXISTS idx_productos_marca ON productos(marca);
CREATE INDEX IF NOT EXISTS idx_productos_precio ON productos(precio);
CREATE INDEX IF NOT EXISTS idx_productos_activos ON productos(esta_activo) WHERE esta_activo = TRUE;

CREATE INDEX IF NOT EXISTS idx_usuarios_correo ON usuarios(correo_electronico);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(id_rol);

CREATE INDEX IF NOT EXISTS idx_pedidos_usuario ON pedidos(id_usuario);
CREATE INDEX IF NOT EXISTS idx_pedidos_estado ON pedidos(id_estado);
CREATE INDEX IF NOT EXISTS idx_pedidos_fecha ON pedidos(fecha_creacion);

CREATE INDEX IF NOT EXISTS idx_inventario_producto ON registro_inventario(id_producto);
CREATE INDEX IF NOT EXISTS idx_inventario_fecha ON registro_inventario(fecha_cambio);

-- Full-text Search Index
CREATE INDEX IF NOT EXISTS idx_productos_busqueda ON productos USING gin(to_tsvector('spanish', nombre || ' ' || descripcion));

-- Geographical Index
CREATE INDEX IF NOT EXISTS idx_ubicaciones_geo ON ubicaciones USING gist(coordenadas);

-- Authentication Index
CREATE INDEX IF NOT EXISTS idx_usuarios_auth ON usuarios(nombre_usuario, correo_electronico) WHERE esta_activo;

-- VIEWS (Remove Duplicates)
CREATE OR REPLACE VIEW productos_populares AS
SELECT 
    p.id_producto, 
    p.nombre, 
    p.precio, 
    COUNT(ip.id_item_pedido) AS total_vendido
FROM productos p
LEFT JOIN items_pedido ip ON p.id_producto = ip.id_producto
GROUP BY p.id_producto, p.nombre, p.precio
ORDER BY total_vendido DESC;

CREATE OR REPLACE VIEW inventario_bajo AS
SELECT 
    id_producto, 
    nombre, 
    cantidad_disponible
FROM productos
WHERE cantidad_disponible < 10
ORDER BY cantidad_disponible ASC;

CREATE OR REPLACE VIEW resumen_ventas AS
SELECT 
    DATE_TRUNC('month', p.fecha_creacion) AS mes,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    SUM(p.total) AS ingresos_totales,
    AVG(p.total) AS valor_promedio_pedido
FROM pedidos p
GROUP BY DATE_TRUNC('month', p.fecha_creacion)
ORDER BY mes DESC;

-- Utility Function for Updating Timestamps
CREATE OR REPLACE FUNCTION public.actualizar_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
  NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add timestamp column if missing
ALTER TABLE pedidos 
ADD COLUMN fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Update existing views
CREATE OR REPLACE VIEW resumen_ventas AS
SELECT 
    DATE_TRUNC('month', p.fecha_creacion) AS mes,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    SUM(p.total) AS ingresos_totales,
    AVG(p.total) AS valor_promedio_pedido
FROM pedidos p
GROUP BY DATE_TRUNC('month', p.fecha_creacion)
ORDER BY mes DESC;