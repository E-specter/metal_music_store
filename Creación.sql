-- Crear base de datos
CREATE DATABASE metal_music_store
    WITH ENCODING = 'UTF8'
    LC_COLLATE = 'es_ES.UTF-8'
    LC_CTYPE = 'es_ES.UTF-8'
    TEMPLATE = template0;

-- Crear un rol/usuario dedicado (opcionalmente con contraseña segura)
CREATE ROLE metal_user WITH LOGIN PASSWORD 'SecurePass123!';
GRANT CONNECT ON DATABASE metal_music_store TO metal_user;

-- Asignar permisos básicos al usuario
\c metal_music_store -- Conectarse a la base de datos
GRANT USAGE ON SCHEMA public TO metal_user;

-----------------------------------------------------------------------------------------
-- BUENAS PRÁCTICAS PREVIAS A LA CREACIÓN DE BASE DE DATOS
-- Activar extensión para UUIDs si se desea usar en el futuro
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Opcional: timestamps automáticos con trigger para actualizaciones
CREATE OR REPLACE FUNCTION actualizar_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
   NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

-- Tabla de Roles (Control de acceso)
CREATE TABLE roles (
    id_rol SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(20) NOT NULL UNIQUE,
    descripcion TEXT,
    permisos JSONB NOT NULL DEFAULT '{}',
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Usuarios
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(50) UNIQUE NOT NULL,
    correo_electronico VARCHAR(255) UNIQUE NOT NULL,
    contrasena_hash VARCHAR(255) NOT NULL,
    nombres VARCHAR(100),
    apellidos VARCHAR(100),
    telefono VARCHAR(20),
    direccion JSONB,
    id_rol INTEGER NOT NULL REFERENCES roles(id_rol),
    esta_activo BOOLEAN DEFAULT TRUE,
    ultimo_acceso TIMESTAMP WITH TIME ZONE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT correo_valido CHECK (correo_electronico ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);

-- Tabla de Categorías de Productos
CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    id_categoria_padre INTEGER REFERENCES categorias(id_categoria),
    slug VARCHAR(100) UNIQUE NOT NULL,
    esta_activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Productos
CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    codigo_sku VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL CHECK (precio > 0),
    costo DECIMAL(10, 2),
    cantidad_disponible INTEGER NOT NULL CHECK (cantidad_disponible >= 0),
    id_categoria INTEGER REFERENCES categorias(id_categoria),
    marca VARCHAR(100),
    talla VARCHAR(50),
    material VARCHAR(100),
    peso DECIMAL(10, 2),
    esta_activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    atributos JSONB DEFAULT '{}'
);

-- Tabla de Imágenes de Productos
CREATE TABLE imagenes_productos (
    id_imagen SERIAL PRIMARY KEY,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    url_imagen VARCHAR(255) NOT NULL,
    texto_alternativo VARCHAR(255),
    es_principal BOOLEAN DEFAULT FALSE,
    orden_visualizacion INTEGER DEFAULT 0,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Listas de Deseos
CREATE TABLE listas_deseos (
    id_lista_deseos SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    es_privada BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_usuario, nombre)
);

-- Tabla de Items en Listas de Deseos
CREATE TABLE items_lista_deseos (
    id_item_lista_deseos SERIAL PRIMARY KEY,
    id_lista_deseos INTEGER NOT NULL REFERENCES listas_deseos(id_lista_deseos) ON DELETE CASCADE,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    fecha_agregado TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_lista_deseos, id_producto)
);

-- Tabla de Carritos de Compras
CREATE TABLE carritos_compras (
    id_carrito SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_usuario)
);

-- Tabla de Items en Carritos
CREATE TABLE items_carrito (
    id_item_carrito SERIAL PRIMARY KEY,
    id_carrito INTEGER NOT NULL REFERENCES carritos_compras(id_carrito) ON DELETE CASCADE,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    fecha_agregado TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_carrito, id_producto)
);

-- Tabla de Pedidos
CREATE TABLE pedidos (
    id_pedido SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario),
    numero_pedido VARCHAR(50) UNIQUE NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('pendiente', 'procesando', 'enviado', 'entregado', 'cancelado', 'reembolsado')),
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal > 0),
    impuestos DECIMAL(10, 2) NOT NULL DEFAULT 0,
    costo_envio DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL CHECK (total > 0),
    direccion_envio JSONB NOT NULL,
    direccion_facturacion JSONB NOT NULL,
    metodo_pago VARCHAR(50) NOT NULL,
    estado_pago VARCHAR(20) NOT NULL CHECK (estado_pago IN ('pendiente', 'pagado', 'fallido', 'reembolsado')),
    notas TEXT,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Items de Pedidos
CREATE TABLE items_pedido (
    id_item_pedido SERIAL PRIMARY KEY,
    id_pedido INTEGER NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario > 0),
    precio_total DECIMAL(10, 2) NOT NULL CHECK (precio_total > 0),
    descuento DECIMAL(10, 2) DEFAULT 0
);

-- Tabla de Historial de Precios (para análisis y auditoría)
CREATE TABLE historial_precios (
    id_historial_precio SERIAL PRIMARY KEY,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    precio_anterior DECIMAL(10, 2) NOT NULL,
    precio_nuevo DECIMAL(10, 2) NOT NULL,
    modificado_por INTEGER REFERENCES usuarios(id_usuario),
    razon_cambio TEXT,
    fecha_cambio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Inventario (registro detallado de movimientos)
CREATE TABLE registro_inventario (
    id_registro SERIAL PRIMARY KEY,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    cambio_cantidad INTEGER NOT NULL,
    nueva_cantidad INTEGER NOT NULL,
    tipo_cambio VARCHAR(20) NOT NULL CHECK (tipo_cambio IN ('compra', 'devolucion', 'ajuste', 'daño', 'reabastecimiento')),
    id_referencia INTEGER, -- Puede ser id_pedido u otro ID relevante
    notas TEXT,
    modificado_por INTEGER REFERENCES usuarios(id_usuario),
    fecha_cambio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Reseñas de Productos
CREATE TABLE reseñas_productos (
    id_reseña SERIAL PRIMARY KEY,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario),
    calificacion SMALLINT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    titulo VARCHAR(100),
    comentario TEXT,
    esta_aprobada BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_producto, id_usuario)
);

------------------------------------------------------------------------------------------
-- ESQUEMAS
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
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_creacion);

-- Índices para historial de inventario
CREATE INDEX idx_inventario_producto ON registro_inventario(id_producto);
CREATE INDEX idx_inventario_fecha ON registro_inventario(fecha_cambio);


------------------------------------------------------------------------------------------
-- VISTAS ÚTILES

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
