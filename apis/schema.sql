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

-- Asignar permisos a esquemas
GRANT USAGE ON SCHEMA api_public TO api_public;
GRANT USAGE ON SCHEMA api_customer TO api_customer;
GRANT USAGE ON SCHEMA api_admin TO api_admin;
GRANT USAGE ON SCHEMA api_delivery TO api_delivery;

-- Configurar permisos por defecto
ALTER DEFAULT PRIVILEGES IN SCHEMA api_public GRANT EXECUTE ON FUNCTIONS TO api_public;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_customer GRANT EXECUTE ON FUNCTIONS TO api_customer, api_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_admin GRANT EXECUTE ON FUNCTIONS TO api_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA api_delivery GRANT EXECUTE ON FUNCTIONS TO api_delivery;


-- Corrected Policy Creation Syntax
CREATE POLICY IF NOT EXISTS admin_access ON usuarios
    FOR ALL
    USING (current_user = 'admin' OR id_usuario = (SELECT id_usuario FROM usuarios WHERE nombre_usuario = current_user));

CREATE POLICY IF NOT EXISTS user_own_profile ON usuarios
    FOR SELECT TO api_customer
    USING (id_usuario = current_setting('app.current_user_id')::UUID);

CREATE POLICY IF NOT EXISTS admin_view_all_users ON usuarios
    FOR SELECT TO api_admin
    USING (true);

CREATE POLICY IF NOT EXISTS user_update_own_profile ON usuarios
    FOR UPDATE TO api_customer
    USING (id_usuario = current_setting('app.current_user_id')::UUID)
    WITH CHECK (id_usuario = current_setting('app.current_user_id')::UUID);

-- Corrected Policy Creation Syntax
-- Drop existing policies first to avoid conflicts
DO $$
BEGIN
    -- Attempt to drop existing policies
    BEGIN
        DROP POLICY IF EXISTS admin_access ON usuarios;
    EXCEPTION WHEN OTHERS THEN
        -- Ignore if policy doesn't exist
        RAISE NOTICE 'Policy admin_access does not exist';
    END;

    BEGIN
        DROP POLICY IF EXISTS metal_user_full_access ON usuarios;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Policy metal_user_full_access does not exist';
    END;

    BEGIN
        DROP POLICY IF EXISTS user_own_profile ON usuarios;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Policy user_own_profile does not exist';
    END;

    BEGIN
        DROP POLICY IF EXISTS admin_view_all_users ON usuarios;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Policy admin_view_all_users does not exist';
    END;

    BEGIN
        DROP POLICY IF EXISTS user_update_own_profile ON usuarios;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Policy user_update_own_profile does not exist';
    END;
END $$;

-- Recreate policies
CREATE POLICY admin_access ON usuarios
    FOR ALL
    USING (current_user = 'admin' OR id_usuario = (SELECT id_usuario FROM usuarios WHERE nombre_usuario = current_user));

CREATE POLICY metal_user_full_access ON usuarios
    FOR ALL TO metal_user
    USING (true) WITH CHECK (true);

CREATE POLICY user_own_profile ON usuarios
    FOR SELECT TO api_customer
    USING (id_usuario = current_setting('app.current_user_id')::uuid);

CREATE POLICY admin_view_all_users ON usuarios
    FOR SELECT TO api_admin
    USING (true);

CREATE POLICY user_update_own_profile ON usuarios
    FOR UPDATE TO api_customer
    USING (id_usuario = current_setting('app.current_user_id')::uuid)
    WITH CHECK (id_usuario = current_setting('app.current_user_id')::uuid);

    