-- 03_indices_vistas.sql
-- Este script contiene únicamente la creación de índices y vistas para la base de datos metal_music_store.
-- Ejecutar después de 02_tablas.sql.

-- INDICES

-- Índices para búsquedas frecuentes
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_marca ON productos(marca);
CREATE INDEX idx_productos_precio ON productos(precio);
CREATE INDEX idx_productos_activos ON productos(esta_activo) WHERE esta_activo = TRUE;

-- Índices para consultas de usuarios
CREATE INDEX idx_usuarios_correo ON usuarios(correo_electronico);
CREATE INDEX idx_usuarios_rol ON usuarios(id_rol);

-- Índices para pedidos
CREATE INDEX idx_pedidos_usuario ON pedidos(id_usuario);
CREATE INDEX idx_pedidos_estado ON pedidos(id_estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_creacion);

-- Índices para historial de inventario
CREATE INDEX idx_inventario_producto ON registro_inventario(id_producto);
CREATE INDEX idx_inventario_fecha ON registro_inventario(fecha_cambio);

-- OPTIMIZACIÓN

-- Optimización de consultas
CREATE INDEX idx_pedidos_usuario ON pedidos(id_usuario);
CREATE INDEX idx_pedidos_estado ON pedidos(id_estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_creacion);

-- Optimización de índices
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_marca ON productos(marca);
CREATE INDEX idx_productos_precio ON productos(precio);
CREATE INDEX idx_productos_activos ON productos(esta_activo) WHERE esta_activo = TRUE;

-- Optimización de vistas
CREATE VIEW productos_populares AS
SELECT p.id_producto, p.nombre, p.precio, COUNT(ip.id_item_pedido) AS total_vendido
FROM productos p
LEFT JOIN items_pedido ip ON p.id_producto = ip.id_producto
GROUP BY p.id_producto
ORDER BY total_vendido DESC;

-- Optimización de índices
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_marca ON productos(marca);
CREATE INDEX idx_productos_precio ON productos(precio);
CREATE INDEX idx_productos_activos ON productos(esta_activo) WHERE esta_activo = TRUE;

-- Optimización de vistas
CREATE VIEW productos_populares AS
SELECT p.id_producto, p.nombre, p.precio, COUNT(ip.id_item_pedido) AS total_vendido
FROM productos p
LEFT JOIN items_pedido ip ON p.id_producto = ip.id_producto
GROUP BY p.id_producto
ORDER BY total_vendido DESC;

-- Optimización de índices
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_marca ON productos(marca);
CREATE INDEX idx_productos_precio ON productos(precio);
CREATE INDEX idx_productos_activos ON productos(esta_activo) WHERE esta_activo = TRUE;

-- VISTAS

-- Vista para productos populares
CREATE VIEW productos_populares AS
SELECT p.id_producto, p.nombre, p.precio, COUNT(ip.id_item_pedido) AS total_vendido
FROM productos p
LEFT JOIN items_pedido ip ON p.id_producto = ip.id_producto
GROUP BY p.id_producto
ORDER BY total_vendido DESC;

-- Vista para inventario bajo
CREATE VIEW inventario_bajo AS
SELECT id_producto, nombre, cantidad_disponible
FROM productos
WHERE cantidad_disponible < 10
ORDER BY cantidad_disponible ASC;

-- Vista para resumen de ventas
CREATE VIEW resumen_ventas AS
SELECT 
    DATE_TRUNC('month', p.fecha_creacion) AS mes,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    SUM(p.total) AS ingresos_totales,
    AVG(p.total) AS valor_promedio_pedido
FROM pedidos p
GROUP BY DATE_TRUNC('month', p.fecha_creacion)
ORDER BY mes DESC;
