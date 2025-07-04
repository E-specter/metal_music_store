-- 00_crear_db_y_usuario.sql
-- Este script crea la base de datos y el usuario/rol principal.

CREATE DATABASE metal_music_store
    WITH ENCODING = 'UTF8',
    LC_COLLATE = 'es_ES.UTF-8',
    LC_CTYPE = 'es_ES.UTF-8';

--TUNNING DE LA BASE DE DATOS (metal_music_store)
-- 1. CREACION DE ROLES
-- Crear un rol/usuario dedicado (con contraseña segura)
CREATE ROLE metal_user WITH LOGIN PASSWORD 'U1eYPplMQa2ksaaM1YyT';
GRANT CONNECT ON DATABASE metal_music_store TO metal_user;

-- 2. IMPLEMENTACION DE EXTENSIONES
-- Instalación de PostGIS: Geolocalización de tiendas
CREATE EXTENSION postgis;

-- Instalación de pgcrypto: Encriptación de contraseñas
CREATE EXTENSION pgcrypto;

-- Instalación de pg_stat_statements: Monitoreo de consultas
CREATE EXTENSION pg_stat_statements;

-- Instalación de pgaudit: Auditoría de seguridad
CREATE EXTENSION pgaudit;

-- Instalación de pg_trgm: Búsqueda por similaridad
CREATE EXTENSION pg_trgm;

-- Instalación de pg_stat_statements: Monitoreo de consultas
CREATE EXTENSION pg_stat_statements;

-- Instalación de uuid-ossp: Generación de UUIDs
CREATE EXTENSION uuid-ossp;

-- Enmascaramiento de datos para reportes
CREATE EXTENSION anon;


-- 3. CONFIGURACIONES DE SEGURIDAD
-- Forzar conexiones SSL
ALTER ROLE metal_user SET ssl = 'require';


SECURITY LABEL FOR anon ON COLUMN usuarios.contrasena_hash 
IS 'MASKED WITH VALUE NULL';

-- 4. AMPLIACION DE ESCALABILIDAD

-- Particionamiento de registros de auditoría
CREATE TABLE auditoria_accesos (
    id SERIAL PRIMARY KEY,
    usuario VARCHAR(100),
    accion VARCHAR(50),
    tabla_afectada VARCHAR(100),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    fecha_accion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (fecha_accion);

-- 5. CONFIGURACIONES DE MONITOREO

-- Habilitar estadísticas avanzadas
ALTER SYSTEM SET track_io_timing = on;
ALTER SYSTEM SET track_functions = all;



-------------------------------------------------------------------------------------------------
-- Configurar PgBouncer para manejar conexiones concurrentes
[databases]
metal_music_store = host=localhost port=5432 dbname=metal_music_store

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 50

-------------------------------------------------------------------------------------------------
-- Restringir acceso a datos sensibles
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- Solo admins ven todos los usuarios
CREATE POLICY admin_access ON usuarios
    USING (current_user = 'admin' OR id_usuario = (SELECT id_usuario FROM usuarios WHERE nombre_usuario = current_user));

-- Enmascaramiento de datos
CREATE EXTENSION IF NOT EXISTS anon;
SECURITY LABEL FOR anon ON COLUMN usuarios.contrasena_hash IS 'MASKED WITH VALUE NULL';

-- Auditoria
-- Habilitar auditoría en postgresql.conf
pgaudit.log = 'all, -misc'
pgaudit.log_relation = on
