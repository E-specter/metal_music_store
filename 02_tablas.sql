-- 02_tablas.sql
-- Este script contiene la creación de tablas con soporte para PostGIS
-- Ejecutar después de crear la extensión PostGIS (01_estructura.sql)

-- ROLES
-- Tabla de Roles (Control de acceso)
CREATE TABLE roles (
  id_rol SERIAL PRIMARY KEY,
  nombre_rol VARCHAR(20) NOT NULL UNIQUE,
  descripcion TEXT,
  permisos JSONB NOT NULL DEFAULT '{}'::jsonb
);


-- USUARIOS Y UBICACIONES
-- Tabla de Ubicaciones con JSONB
CREATE TABLE ubicaciones (
  id_ubicacion SERIAL PRIMARY KEY,
  direccion JSONB NOT NULL CHECK (
    jsonb_typeof(direccion) = 'object' AND
    direccion ? 'linea1' AND
    direccion ? 'distrito' AND
    direccion ? 'provincia' AND
    direccion ? 'departamento' AND
    direccion ? 'codigo_postal' AND
    direccion ? 'pais'
  ),
  coordenadas GEOMETRY(POINT, 4326)
);
/*
formato JSONB de la direccion:
{
  "linea1": "Av. Javier Prado 123",
  "linea2": "Oficina 501", (opcional)
  "distrito": "San Isidro",
  "provincia": "Lima",
  "departamento": "Lima",
  "codigo_postal": "15076",
  "pais": "Peru", 
  "referencia": "Frente al parque" (opcional)
}
*/

-- Tabla de Usuarios
CREATE TABLE usuarios (
  id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_secuencial SERIAL UNIQUE,
  nombre_usuario VARCHAR(50) UNIQUE NOT NULL,
  correo_electronico VARCHAR(255) UNIQUE NOT NULL CHECK (
    correo_electronico ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'
  ),
  contrasena_hash VARCHAR(255) NOT NULL,
  nombres VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100) NOT NULL,
  telefono VARCHAR(20) CHECK (telefono ~ '^[0-9]{9}$'),
  id_ubicacion_principal INTEGER REFERENCES ubicaciones(id_ubicacion),
  direcciones_adicionales JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (
    jsonb_typeof(direcciones_adicionales) = 'array'
  ),
  id_rol INTEGER NOT NULL REFERENCES roles(id_rol),
  esta_activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- PRODUCTOS
-- Tabla de Categorías de Producto
CREATE TABLE categorias (
  id_categoria SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  descripcion TEXT,
  id_categoria_padre INTEGER REFERENCES categorias(id_categoria),
  esta_activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT nombre_unico_por_nivel UNIQUE (nombre, id_categoria_padre)
);

-- Tabla de Detalles Técnicos de Productos
CREATE TABLE detalles_productos (
  id_detalle_producto SERIAL PRIMARY KEY,
  tipo_producto VARCHAR(50) NOT NULL,
  especificaciones JSONB NOT NULL DEFAULT '{}'::jsonb,
  peso DECIMAL(10, 2) CHECK (peso > 0), -- en kg
  dimensiones DECIMAL(10, 2)[3] CHECK (array_length(dimensiones, 1) = 3), -- [x, y, z]
  material_principal VARCHAR(100),
  materiales_secundarios JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (
    jsonb_typeof(materiales_secundarios) = 'array'
  ),
  cuidados_especiales JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (
    jsonb_typeof(cuidados_especiales) = 'object'
  )
);
/*
formato JSONB de los materiales secundarios:
[
  {"material": "Algodón", "porcentaje": 80},
  {"material": "Poliester", "porcentaje": 20}
]
formato JSONB de los cuidados especiales:
{
  "lavado": "Lavar a máquina con agua fría",
  "secado": "Secar a la sombra",
  "planchado": "Planchar a baja temperatura"
}
*/


-- Tabla de Productos (Optimizada con referencia a detalles técnicos)
CREATE TABLE productos (
  id_producto UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_secuencial SERIAL UNIQUE,
  codigo_sku VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10, 2) NOT NULL CHECK (precio > 0),
  costo DECIMAL(10, 2) CHECK (costo > 0),
  cantidad_disponible INTEGER NOT NULL CHECK (cantidad_disponible >= 0) DEFAULT 0,
  id_categoria INTEGER NOT NULL REFERENCES categorias(id_categoria),
  id_detalle_producto INTEGER REFERENCES detalles_productos(id_detalle_producto),
  marca VARCHAR(100),
  talla VARCHAR(50),
  esta_activo BOOLEAN NOT NULL DEFAULT TRUE,
  atributos_generales JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (
    jsonb_typeof(atributos_generales) = 'object'
  )
);
/*
formato JSONB de los atributos generales:
{
  "color": "Azul marino",
  "temporada": "Verano 2023",
  "garantia": "6 meses"
}*/

-- Tabla de Imágenes de Productos
CREATE TABLE imagenes_productos (
  id_imagen SERIAL PRIMARY KEY,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  url_imagen VARCHAR(255) NOT NULL,
  texto_alternativo VARCHAR(255),
  es_principal BOOLEAN NOT NULL DEFAULT FALSE,
  orden_visualizacion INTEGER NOT NULL DEFAULT 0
);

-- LISTAS DE DESEOS
-- Tabla de Listas de Deseos
CREATE TABLE listas_deseos (
  id_lista_deseos UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_secuencial SERIAL UNIQUE,
  id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  nombre VARCHAR(100) NOT NULL,
  es_privada BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT lista_unica_por_usuario UNIQUE (id_usuario, nombre)
);

-- Tabla de Items en Listas de Deseos
CREATE TABLE items_lista_deseos (
  id_item_lista_deseos SERIAL PRIMARY KEY,
  id_lista_deseos UUID NOT NULL REFERENCES listas_deseos(id_lista_deseos) ON DELETE CASCADE,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  CONSTRAINT producto_unico_por_lista UNIQUE (id_lista_deseos, id_producto)
);

-- CARRITO DE COMPRAS --
-- Tabla de Carritos de Compras
CREATE TABLE carritos_compras (
  id_carrito UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_secuencial SERIAL UNIQUE,
  id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  CONSTRAINT carrito_unico_por_usuario UNIQUE (id_usuario)
);

-- Tabla de Items en Carritos
CREATE TABLE items_carrito (
  id_item_carrito SERIAL PRIMARY KEY,
  id_carrito UUID NOT NULL REFERENCES carritos_compras(id_carrito) ON DELETE CASCADE,
  id_producto UUID NOT NULL REFERENCES productos(id_producto),
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  CONSTRAINT producto_unico_por_carrito UNIQUE (id_carrito, id_producto)
);

-- PEDIDOS --
-- Tabla de Estados de Pedido
CREATE TABLE estados_pedido (
  id_estado SERIAL PRIMARY KEY,
  codigo_estado VARCHAR(20) UNIQUE NOT NULL,
  nombre_estado VARCHAR(50) NOT NULL,
  descripcion TEXT,
  es_final BOOLEAN NOT NULL DEFAULT FALSE,
  orden_flujo INTEGER NOT NULL
);

-- Tabla de Métodos de Pago
CREATE TABLE metodos_pago (
  id_metodo_pago SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  descripcion TEXT,
  requiere_confirmacion BOOLEAN NOT NULL DEFAULT FALSE,
  esta_activo BOOLEAN NOT NULL DEFAULT TRUE,
  configuracion JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (
    jsonb_typeof(configuracion) = 'object'
  )
);

-- Tabla de Pedidos
CREATE TABLE pedidos (
  id_pedido UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario),
  numero_pedido VARCHAR(50) UNIQUE NOT NULL,
  id_estado INTEGER NOT NULL REFERENCES estados_pedido(id_estado),
  subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal > 0),
  impuestos DECIMAL(10, 2) NOT NULL DEFAULT 0,
  costo_envio DECIMAL(10, 2) NOT NULL DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL CHECK (total > 0),
  id_metodo_pago INTEGER REFERENCES metodos_pago(id_metodo_pago),
  estado_pago BOOLEAN NOT NULL DEFAULT FALSE,
  direccion JSONB NOT NULL CHECK (
    jsonb_typeof(direccion) = 'object' AND
    direccion ? 'linea1' AND
    direccion ? 'distrito' AND
    direccion ? 'provincia' AND
    direccion ? 'departamento'
  ),
  informacion_remitente JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (
    jsonb_typeof(informacion_remitente) = 'object'
  ),
  coordenadas GEOMETRY(POINT, 4326),
  notas TEXT
);

-- Tabla de Items de Pedido
CREATE TABLE items_pedido (
  id_item_pedido SERIAL PRIMARY KEY,
  id_pedido UUID NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
  id_producto UUID NOT NULL REFERENCES productos(id_producto),
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario > 0),
  precio_total DECIMAL(10, 2) NOT NULL CHECK (precio_total > 0),
  descuento DECIMAL(10, 2) NOT NULL DEFAULT 0,
  impuestos DECIMAL(10, 2) NOT NULL DEFAULT 0
);

-- Tabla de Reseñas de Productos
CREATE TABLE resenas_productos (
  id_resena SERIAL PRIMARY KEY,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario),
  calificacion INTEGER NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
  comentario TEXT,
  esta_aprobado BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT reseña_unica_por_producto_usuario UNIQUE (id_producto, id_usuario)
);

-- =============================================
-- TABLAS DE AUDITORÍA E HISTORIALES
-- =============================================

-- Tabla de Registro de Inventario
CREATE TABLE registro_inventario (
  id_registro SERIAL PRIMARY KEY,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  cambio_cantidad INTEGER NOT NULL,
  nueva_cantidad INTEGER NOT NULL,
  tipo_cambio VARCHAR(20) NOT NULL CHECK (
    tipo_cambio IN ('compra', 'venta', 'ajuste', 'perdida', 'devolucion')
  ),
  id_referencia VARCHAR(50), -- Puede ser ID de pedido, factura, etc.
  tipo_referencia VARCHAR(50), -- Tipo de referencia (pedido, ajuste, etc.)
  notas TEXT,
  modificado_por UUID REFERENCES usuarios(id_usuario),
  fecha_cambio TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Historial de Estados de Pedido
CREATE TABLE historial_estados_pedido (
  id_historial SERIAL PRIMARY KEY,
  id_pedido UUID NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
  id_estado INTEGER NOT NULL REFERENCES estados_pedido(id_estado),
  id_usuario UUID REFERENCES usuarios(id_usuario),
  notas TEXT,
  fecha_cambio TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Historial de Precios
CREATE TABLE historial_precios (
  id_historial_precio SERIAL PRIMARY KEY,
  id_producto UUID NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
  precio_anterior DECIMAL(10, 2) NOT NULL,
  precio_nuevo DECIMAL(10, 2) NOT NULL,
  modificado_por UUID REFERENCES usuarios(id_usuario),
  razon_cambio TEXT,
  fecha_cambio TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TRIGGERS PARA AUDITORÍA
-- =============================================

-- Trigger para registrar cambios en productos
CREATE OR REPLACE FUNCTION registrar_cambio_producto()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.precio <> NEW.precio THEN
    INSERT INTO historial_precios (
      id_producto, precio_anterior, precio_nuevo, modificado_por, razon_cambio
    ) VALUES (
      NEW.id_producto, OLD.precio, NEW.precio, current_setting('app.current_user_id', TRUE)::UUID, 'Actualización de precio'
    );
  END IF;
  
  IF OLD.cantidad_disponible <> NEW.cantidad_disponible THEN
    INSERT INTO registro_inventario (
      id_producto, cambio_cantidad, nueva_cantidad, tipo_cambio, modificado_por
    ) VALUES (
      NEW.id_producto, 
      NEW.cantidad_disponible - OLD.cantidad_disponible, 
      NEW.cantidad_disponible,
      CASE 
        WHEN NEW.cantidad_disponible > OLD.cantidad_disponible THEN 'compra'
        ELSE 'venta'
      END,
      current_setting('app.current_user_id', TRUE)::UUID
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auditoria_producto
AFTER UPDATE ON productos
FOR EACH ROW
EXECUTE FUNCTION registrar_cambio_producto();

-- Trigger para registrar cambios de estado en pedidos
CREATE OR REPLACE FUNCTION registrar_cambio_estado_pedido()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.id_estado <> NEW.id_estado THEN
    INSERT INTO historial_estados_pedido (
      id_pedido, id_estado, id_usuario, notas
    ) VALUES (
      NEW.id_pedido, NEW.id_estado, current_setting('app.current_user_id', TRUE)::UUID, 'Cambio de estado'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auditoria_estado_pedido
AFTER UPDATE ON pedidos
FOR EACH ROW
EXECUTE FUNCTION registrar_cambio_estado_pedido();

-- Trigger para registrar creación de pedidos
CREATE OR REPLACE FUNCTION registrar_nuevo_pedido()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO historial_estados_pedido (
    id_pedido, id_estado, id_usuario, notas
  ) VALUES (
    NEW.id_pedido, NEW.id_estado, NEW.id_usuario, 'Pedido creado'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auditoria_nuevo_pedido
AFTER INSERT ON pedidos
FOR EACH ROW
EXECUTE FUNCTION registrar_nuevo_pedido();