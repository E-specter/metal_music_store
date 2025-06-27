-- 01_estructura.sql
-- Este script asume que la base de datos ya existe y que el usuario/rol ha sido creado.
-- Debe ejecutarse después de 00_crear_db_y_usuario.sql

-- Conectarse a la base de datos (solo para psql)
\c metal_music_store

-- Asignar permisos básicos al usuario
GRANT USAGE ON SCHEMA public TO metal_user;

-----------------------------------------------------------------------------------------
-- BUENAS PRÁCTICAS PREVIAS A LA CREACIÓN DE BASE DE DATOS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE OR REPLACE FUNCTION public.actualizar_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
  NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;