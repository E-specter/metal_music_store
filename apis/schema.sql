-- 6. CONFIGURACIONES DE API

-- Crear esquemas para API
CREATE SCHEMA IF NOT EXISTS api_public;   -- Visitantes
CREATE SCHEMA IF NOT EXISTS api_customer; -- Clientes
CREATE SCHEMA IF NOT EXISTS api_admin;    -- Administradores
CREATE SCHEMA IF NOT EXISTS api_delivery; -- Delivery

-- =============================================
-- CONFIGURACIÓN DE ROLES DEL SISTEMA
-- =============================================

-- Crear roles de aplicación
CREATE ROLE api_public WITH LOGIN PASSWORD 'public_api';
CREATE ROLE api_customer WITH LOGIN PASSWORD 'customer_api';
CREATE ROLE api_admin WITH LOGIN PASSWORD 'admin_api';
CREATE ROLE api_delivery WITH LOGIN PASSWORD 'delivery_api';
CREATE IF NOT EXISTS ROLE metal_user WITH LOGIN PASSWORD 'metal_api' BYPASSRLS;

-- Asignar permisos a esquemas
GRANT USAGE ON SCHEMA api_public TO api_public;
GRANT USAGE ON SCHEMA api_customer TO api_customer;
GRANT USAGE ON SCHEMA api_admin TO api_admin;
GRANT USAGE ON SCHEMA api_delivery TO api_delivery;

-- Metal_user tiene acceso total
GRANT USAGE ON ALL SCHEMAS IN DATABASE TO metal_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public, api_public, api_customer, api_admin, api_delivery TO metal_user;

-- Configurar permisos por defecto
ALTER DEFAULT PRIVILEGES IN SCHEMA api_public GRANT EXECUTE ON FUNCTIONS TO api_public;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_customer GRANT EXECUTE ON FUNCTIONS TO api_customer, api_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_admin GRANT EXECUTE ON FUNCTIONS TO api_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_delivery GRANT EXECUTE ON FUNCTIONS TO api_delivery;
