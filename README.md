# metal_music_store
Repositorio de BYH - Music Store


# Implementación de Triggers para auditoría

Se implementaron triggers para auditar las tablas de la base de datos, lo que permite rastrear los cambios en las tablas de la base de datos.

# Implementación de Procedimientos Almacenados
Se implementaron procedimientos almacenados para obtener las fechas de creación y actualización de las tablas de la base de datos.
## Gestión de inventario mejorada

```sql
-- Función para actualizar inventario
CREATE OR REPLACE FUNCTION actualizar_inventario()
RETURNS TRIGGER AS $$
DECLARE
  diff INTEGER;
BEGIN
  IF TG_OP = 'INSERT' THEN
    diff := NEW.cantidad;
  ELSIF TG_OP = 'UPDATE' THEN
    diff := NEW.cantidad - OLD.cantidad;
  ELSE
    diff := -OLD.cantidad;
  END IF;

  INSERT INTO registro_inventario(
    id_producto, cambio_cantidad, nueva_cantidad, tipo_cambio
  ) VALUES (
    COALESCE(NEW.id_producto, OLD.id_producto),
    diff,
    NEW.cantidad_disponible,
    TG_OP
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_inventario
AFTER INSERT OR UPDATE OR DELETE ON items_pedido
FOR EACH ROW EXECUTE FUNCTION actualizar_inventario();
```


# Implementación de Índices y Optimización

Se implementaron índices para optimizar las consultas de las tablas de la base de datos.

# Implementación de Vistas

Se implementaron vistas para optimizar las consultas de las tablas de la base de datos.

# Implementación de Tablas Normalizadas

Se implementaron tablas normalizadas para optimizar las consultas de las tablas de la base de datos.

# Modelado de tablas de bandas y eventos
```sql
CREATE TABLE bandas (
    id_banda UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(255) NOT NULL,
    genero VARCHAR(100),
    pais_origen VARCHAR(100),
    anio_fundacion INTEGER,
    biografia TEXT,
    discografia JSONB
);

CREATE TABLE eventos (
    id_evento SERIAL PRIMARY KEY,
    id_banda INTEGER REFERENCES bandas(id_banda),
    nombre_evento VARCHAR(255) NOT NULL,
    fecha TIMESTAMP NOT NULL,
    id_ubicacion INTEGER REFERENCES ubicaciones(id_ubicacion),
    entradas_vendidas INTEGER DEFAULT 0,
    capacidad_maxima INTEGER
);
```

# Implementación de Tablas Denormalizadas

Se implementaron tablas denormalizadas para optimizar las consultas de las tablas de la base de datos.

# Implementación de Tablas de Referencia

Se implementaron tablas de referencia para optimizar las consultas de las tablas de la base de datos.

# Implementación de Tablas de Auditoría

Se implementaron tablas de auditoría para optimizar las consultas de las tablas de la base de datos.

## Particionamiento de tablas críticas

# Seguridad y permisos
## Implementación de Tablas de Seguridad

Se implementaron tablas de seguridad para optimizar las consultas de las tablas de la base de datos.

# Integración de PostGIS
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
ALTER TABLE ubicaciones ADD COLUMN coordenadas GEOMETRY(Point, 4326);
CREATE INDEX idx_ubicaciones_geog ON ubicaciones USING GIST(coordenadas);
```

# Integración de sistema de recomendación
```sql
CREATE TABLE similitud_bandas (
    id_banda1 INTEGER REFERENCES bandas(id_banda),
    id_banda2 INTEGER REFERENCES bandas(id_banda),
    puntuacion_similitud DECIMAL(3,2),
    PRIMARY KEY (id_banda1, id_banda2)
);
```







