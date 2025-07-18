CREATE DATABASE metal_music_store
    WITH ENCODING = 'UTF8';

-- =============================================
-- IMPLEMENTACIÓN DE EXTENSIONES
-- =============================================
-- Instalación de PostGIS: Geolocalización de tiendas
CREATE EXTENSION IF NOT EXISTS postgis;

-- Instalación de pg_stat_statements: Monitoreo de consultas
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Instalación de pgaudit: Auditoría de seguridad
CREATE EXTENSION IF NOT EXISTS pgaudit;

-- Instalación de pg_trgm: Búsqueda por similaridad
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Instalación de uuid-ossp: Generación de UUIDs
CREATE EXTENSION IF NOT EXISTS uuid_ossp;

-- EXTENSIONES DE SEGURIDAD
-- pgcrypto: Para funciones criptográficas
/*
  - Encriptación de contraseñas
*/
CREATE EXTENSION IF NOT EXISTS pgcrypto; 
-- pgjwt: Para manejo de JWT
-- CREATE EXTENSION IF NOT EXISTS pgjwt;  -- No disponible en Supabase, usar auth.jwt() 

-- Particionamiento de registros de auditoría
CREATE TABLE auditoria_accesos (
    id BIGINT,
    usuario VARCHAR(100),
    accion VARCHAR(50),
    tabla_afectada VARCHAR(100),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    fecha_accion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, fecha_accion)
) PARTITION BY RANGE (fecha_accion);

-- Asignar permisos básicos al usuario
GRANT USAGE ON SCHEMA public TO metal_user;
