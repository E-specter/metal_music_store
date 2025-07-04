-- 02_tablas.sql
-- Este script contiene la creación de tablas con soporte para PostGIS
-- Ejecutar después de crear la extensión PostGIS (01_estructura.sql)

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS uuid-ossp;

-- Tabla de Roles (Control de acceso)
CREATE TABLE roles (
  id_rol SERIAL PRIMARY KEY,
  nombre_rol VARCHAR(20) NOT NULL UNIQUE,
  descripcion TEXT,
  permisos JSONB NOT NULL DEFAULT '{}',
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Ubicaciones (Optimizada con PostGIS)
/* OBSOLETA
CREATE TABLE ubicaciones (
  id_ubicacion SERIAL PRIMARY KEY,
  direccion_linea1 VARCHAR(255) NOT NULL,
  direccion_linea2 VARCHAR(255),
  ciudad VARCHAR(100) NOT NULL,
  provincia VARCHAR(100) NOT NULL,
  codigo_postal VARCHAR(20),
  pais VARCHAR(100) NOT NULL DEFAULT 'Perú',
  referencia TEXT,
  coordenadas GEOMETRY(POINT, 4326), -- Coordenadas geográficas (lat/long)
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- Índice espacial para búsquedas geográficas
CREATE INDEX idx_ubicaciones_coordenadas ON ubicaciones USING GIST(coordenadas);
*/
-- Tabla de Ubicaciones con JSONB
CREATE TABLE ubicaciones (
  id_ubicacion SERIAL PRIMARY KEY,
  direccion JSONB NOT NULL,
  coordenadas GEOMETRY(POINT, 4326), -- Coordenadas geográficas (lat/long)
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- Índice para búsquedas en campos específicos del JSONB
CREATE INDEX idx_ubicaciones_direccion ON ubicaciones USING GIN (direccion);

-- Tabla de Usuarios (Optimizada con referencia a ubicaciones)
CREATE TABLE usuarios (
  id_usuario UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_secuencial SERIAL UNIQUE,
  nombre_usuario VARCHAR(50) UNIQUE NOT NULL,
  correo_electronico VARCHAR(255) UNIQUE NOT NULL,
  contrasena_hash VARCHAR(255) NOT NULL,
  nombres VARCHAR(100),
  apellidos VARCHAR(100),
  telefono VARCHAR(20),
  id_ubicacion_principal INTEGER REFERENCES ubicaciones(id_ubicacion),
  direcciones_adicionales JSONB DEFAULT '[]'::jsonb, -- Array de objetos JSON con la misma estructura que la tabla ubicaciones
  id_rol INTEGER NOT NULL REFERENCES roles(id_rol),
  esta_activo BOOLEAN DEFAULT TRUE,
  ultimo_acceso TIMESTAMP WITH TIME ZONE,
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT correo_valido CHECK (
    correo_electronico ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'
  )
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

-- Tabla de Detalles Técnicos de Productos (Normalización de atributos específicos)
CREATE TABLE detalles_tecnicos_productos (
  id_detalle_tecnico SERIAL PRIMARY KEY,
  tipo_producto VARCHAR(50) NOT NULL, -- Ej: 'camiseta', 'vinilo', 'accesorio'
  especificaciones JSONB NOT NULL DEFAULT '{}', -- Estructura varía por tipo
  peso DECIMAL(10, 2),
  dimensiones VARCHAR(50), -- Formato: "alto x ancho x profundidad"
  material_principal VARCHAR(100),
  materiales_secundarios VARCHAR(255),
  cuidados_especiales TEXT,
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Productos (Optimizada con referencia a detalles técnicos)
CREATE TABLE productos (
  id_producto UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_secuencial SERIAL UNIQUE,
  codigo_sku VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10, 2) NOT NULL CHECK (precio > 0),
  costo DECIMAL(10, 2),
  cantidad_disponible INTEGER NOT NULL CHECK (cantidad_disponible >= 0),
  id_categoria INTEGER REFERENCES categorias(id_categoria),
  id_detalle_tecnico INTEGER REFERENCES detalles_tecnicos_productos(id_detalle_tecnico),
  marca VARCHAR(100),
  talla VARCHAR(50),
  esta_activo BOOLEAN DEFAULT TRUE,
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  atributos_generales JSONB DEFAULT '{}' -- Para atributos no normalizados
);

-- Tabla de Imágenes de Productos
CREATE TABLE imagenes_productos (
  id_imagen SERIAL PRIMARY KEY,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  url_imagen VARCHAR(255) NOT NULL,
  texto_alternativo VARCHAR(255),
  es_principal BOOLEAN DEFAULT FALSE,
  orden_visualizacion INTEGER DEFAULT 0,
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Listas de Deseos
CREATE TABLE listas_deseos (
  id_lista_deseos UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_secuencial SERIAL UNIQUE,
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
  id_lista_deseos UUID NOT NULL REFERENCES listas_deseos(id_lista_deseos) ON DELETE CASCADE,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  fecha_agregado TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_lista_deseos, id_producto)
);

-- Tabla de Carritos de Compras
CREATE TABLE carritos_compras (
  id_carrito UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_secuencial SERIAL UNIQUE,
  id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_usuario)
);

-- Tabla de Items en Carritos
CREATE TABLE items_carrito (
  id_item_carrito SERIAL PRIMARY KEY,
  id_carrito UUID NOT NULL REFERENCES carritos_compras(id_carrito) ON DELETE CASCADE,
  id_producto UUID NOT NULL REFERENCES productos(id_producto),
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  fecha_agregado TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_carrito, id_producto)
);

-- Tabla de Estados de Pedido (Para normalizar los estados posibles)
CREATE TABLE estados_pedido (
  id_estado SERIAL PRIMARY KEY,
  codigo_estado VARCHAR(20) UNIQUE NOT NULL,
  nombre_estado VARCHAR(50) NOT NULL,
  descripcion TEXT,
  es_estado_final BOOLEAN DEFAULT FALSE,
  orden_flujo INTEGER NOT NULL
);

-- Tabla de Métodos de Pago
CREATE TABLE metodos_pago (
  id_metodo_pago SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  descripcion TEXT,
  requiere_confirmacion BOOLEAN DEFAULT FALSE,
  esta_activo BOOLEAN DEFAULT TRUE,
  configuracion JSONB DEFAULT '{}'
);

-- Tabla de Pedidos (Optimizada con referencias normalizadas)
CREATE TABLE pedidos (
  id_pedido UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_secuencial SERIAL UNIQUE,
  id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario),
  numero_pedido VARCHAR(50) UNIQUE NOT NULL,
  id_estado INTEGER NOT NULL REFERENCES estados_pedido(id_estado),
  subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal > 0),
  impuestos DECIMAL(10, 2) NOT NULL DEFAULT 0,
  costo_envio DECIMAL(10, 2) NOT NULL DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL CHECK (total > 0),
  id_metodo_pago INTEGER REFERENCES metodos_pago(id_metodo_pago),
  estado_pago VARCHAR(20) NOT NULL CHECK (
    estado_pago IN ('pendiente', 'pagado', 'fallido', 'reembolsado')
  ),
  notas TEXT,
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Direcciones de Pedido (Para historial de direcciones)
CREATE TABLE direcciones_pedido (
  id_direccion_pedido SERIAL PRIMARY KEY,
  id_pedido UUID NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
  tipo_direccion VARCHAR(10) NOT NULL CHECK (tipo_direccion IN ('envio', 'facturacion')),
  id_ubicacion INTEGER REFERENCES ubicaciones(id_ubicacion),
  direccion JSONB NOT NULL, -- Estructura estandarizada: {linea1, linea2, ciudad, provincia, codigo_postal, pais, referencia}
  coordenadas GEOMETRY(POINT, 4326), -- Copia de las coordenadas en el momento del pedido
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índice para búsquedas en campos específicos del JSONB
CREATE INDEX idx_direcciones_pedido_direccion ON direcciones_pedido USING GIN (direccion);

-- Tabla de Items de Pedidos (Optimizada)
CREATE TABLE items_pedido (
  id_item_pedido SERIAL PRIMARY KEY,
  id_pedido UUID NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
  id_producto UUID NOT NULL REFERENCES productos(id_producto),
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario > 0),
  precio_total DECIMAL(10, 2) NOT NULL CHECK (precio_total > 0),
  descuento DECIMAL(10, 2) DEFAULT 0,
  impuestos DECIMAL(10, 2) DEFAULT 0,
  datos_producto JSONB -- Copia de los datos del producto en el momento del pedido
);

-- Tabla de Historial de Estados de Pedido (Para tracking completo)
CREATE TABLE historial_estados_pedido (
  id_historial SERIAL PRIMARY KEY,
  id_pedido UUID NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
  id_estado INTEGER NOT NULL REFERENCES estados_pedido(id_estado),
  id_usuario INTEGER REFERENCES usuarios(id_usuario), -- Quién realizó el cambio
  notas TEXT,
  fecha_cambio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Historial de Precios (para análisis y auditoría)
CREATE TABLE historial_precios (
  id_historial_precio SERIAL PRIMARY KEY,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  precio_anterior DECIMAL(10, 2) NOT NULL,
  precio_nuevo DECIMAL(10, 2) NOT NULL,
  modificado_por INTEGER REFERENCES usuarios(id_usuario),
  razon_cambio TEXT,
  fecha_cambio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Inventario (registro detallado de movimientos)
CREATE TABLE registro_inventario (
  id_registro SERIAL PRIMARY KEY,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  cambio_cantidad INTEGER NOT NULL,
  nueva_cantidad INTEGER NOT NULL,
  tipo_cambio VARCHAR(20) NOT NULL CHECK (
    tipo_cambio IN ('compra', 'devolucion', 'ajuste', 'daño', 'reabastecimiento')
  ),
  id_referencia INTEGER, -- Puede ser id_pedido u otro ID relevante
  tipo_referencia VARCHAR(50), -- Para saber a qué tabla pertenece id_referencia
  notas TEXT,
  modificado_por INTEGER REFERENCES usuarios(id_usuario),
  fecha_cambio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Reseñas de Productos
CREATE TABLE resenas_productos (
  id_resena SERIAL PRIMARY KEY,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario),
  calificacion SMALLINT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
  titulo VARCHAR(100),
  comentario TEXT,
  esta_aprobada BOOLEAN DEFAULT FALSE,
  fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(id_producto, id_usuario)
);

-- Vistas especializadas con PostGIS
CREATE OR REPLACE VIEW vista_pedidos_geo AS
SELECT 
    p.id_pedido,
    p.numero_pedido,
    u.nombre_usuario,
    ST_Distance(
        ub1.coordenadas,
        (SELECT coordenadas FROM ubicaciones WHERE id_ubicacion = 1) -- Ubicación del almacén
    ) AS distancia_almacen_km,
    ST_AsText(ub1.coordenadas) AS punto_entrega
FROM 
    pedidos p
JOIN 
    usuarios u ON p.id_usuario = u.id_usuario
JOIN 
    direcciones_pedido dp ON p.id_pedido = dp.id_pedido AND dp.tipo_direccion = 'envio'
JOIN 
    ubicaciones ub1 ON dp.id_ubicacion = ub1.id_ubicacion;