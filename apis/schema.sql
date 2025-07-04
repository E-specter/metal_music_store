-- 6. CONFIGURACIONES DE API

-- Crear esquemas para API
CREATE SCHEMA IF NOT EXISTS api_public;   -- Visitantes
CREATE SCHEMA IF NOT EXISTS api_customer; -- Clientes
CREATE SCHEMA IF NOT EXISTS api_admin;    -- Administradores
CREATE SCHEMA IF NOT EXISTS api_delivery; -- Delivery

-- Crear roles para API
CREATE ROLE api_public WITH LOGIN PASSWORD 'public_api';
CREATE ROLE api_customer WITH LOGIN PASSWORD 'customer_api';
CREATE ROLE api_admin WITH LOGIN PASSWORD 'admin_api';
CREATE ROLE api_delivery WITH LOGIN PASSWORD 'delivery_api';

-- Asignar permisos a roles
GRANT USAGE ON SCHEMA api_public TO api_public;
GRANT USAGE ON SCHEMA api_customer TO api_customer;
GRANT USAGE ON SCHEMA api_admin TO api_admin;
GRANT USAGE ON SCHEMA api_delivery TO api_delivery;

-- Crear políticas de seguridad
CREATE POLICY api_public_policy ON api_public TO api_public;
CREATE POLICY api_customer_policy ON api_customer TO api_customer;
CREATE POLICY api_admin_policy ON api_admin TO api_admin;
CREATE POLICY api_delivery_policy ON api_delivery TO api_delivery;
