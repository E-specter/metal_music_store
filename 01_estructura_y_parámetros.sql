-- 01_estructura.sql
-- Este script asume que la base de datos ya existe y que el usuario/rol ha sido creado.
-- Debe ejecutarse después de 00_crear_db_y_usuario.sql

-- Conectarse a la base de datos (solo para psql)
\c metal_music_store

-- Asignar permisos básicos al usuario
GRANT USAGE ON SCHEMA public TO metal_user;

-- =============================================
-- EXTENSIONES PARA SEGURIDAD
-- =============================================

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- Para funciones criptográficas
CREATE EXTENSION IF NOT EXISTS pgjwt; -- Para manejo de JWT

-- Configuración de seguridad adicional
ALTER SYSTEM SET session_preload_libraries = 'pg_stat_statements,auto_explain';
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements,pg_cron,pgaudit';