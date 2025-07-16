-- Enmascaramiento de datos

SECURITY LABEL FOR anon ON COLUMN usuarios.contrasena_hash IS 'MASKED WITH VALUE NULL';

-- Restringir acceso a datos sensibles
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
-- Solo admins ven todos los usuarios
CREATE POLICY admin_access ON usuarios
    USING (current_user = 'admin' OR id_usuario = (SELECT id_usuario FROM usuarios WHERE nombre_usuario = current_user));

    
-- Auditoria
-- Habilitar auditoría en postgresql.conf
pgaudit.log = 'all, -misc'
pgaudit.log_relation = on


-- MONITOREO
CREATE TABLE seguridad.eventos_auditoria (
  id_evento BIGSERIAL PRIMARY KEY,
  tipo_evento VARCHAR(50) NOT NULL,
  usuario_id UUID,
  direccion_ip INET,
  detalles JSONB,
  fecha_evento TIMESTAMPTZ DEFAULT NOW()
);

CREATE ROLE monitor WITH LOGIN PASSWORD 'monitor_pass';
GRANT CONNECT ON DATABASE current_database() TO monitor;
GRANT USAGE ON SCHEMA seguridad TO monitor;
GRANT SELECT ON seguridad.eventos_auditoria TO monitor;


-- =============================================
-- ROW LEVEL SECURITY (RLS) PARA TABLAS CRÍTICAS
-- =============================================

-- Tabla de usuarios
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- Política para metal_user (acceso completo)
CREATE POLICY metal_user_full_access ON usuarios
  TO metal_user
  USING (true) WITH CHECK (true);

-- Política para que los usuarios vean solo su propio perfil
CREATE POLICY user_own_profile ON usuarios
  FOR SELECT TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID);

-- Política para que los admins vean todos los usuarios
CREATE POLICY admin_view_all_users ON usuarios
  FOR SELECT TO api_admin
  USING (true);

-- Política para actualización de propio perfil
CREATE POLICY user_update_own_profile ON usuarios
  FOR UPDATE TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID)
  WITH CHECK (id_usuario = current_setting('app.current_user_id')::UUID);

-- Tabla de pedidos
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;

-- Política para clientes (solo sus pedidos)
CREATE POLICY customer_own_orders ON pedidos
  FOR ALL TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID)
  WITH CHECK (id_usuario = current_setting('app.current_user_id')::UUID);

-- Política para admins (todos los pedidos)
CREATE POLICY admin_all_orders ON pedidos
  FOR ALL TO api_admin
  USING (true) WITH CHECK (true);

-- Política para repartidores (solo pedidos en estados específicos)
CREATE POLICY delivery_view_orders ON pedidos
  FOR SELECT TO api_delivery
  USING (id_estado IN (
    SELECT id_estado FROM estados_pedido 
    WHERE codigo_estado IN ('por_enviar', 'enviado')
  ));

-- Tabla de productos
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;

-- Política para lectura pública de productos activos
CREATE POLICY public_read_active_products ON productos
  FOR SELECT TO api_public
  USING (esta_activo);

-- Política para clientes (lectura completa)
CREATE POLICY customer_read_products ON productos
  FOR SELECT TO api_customer
  USING (true);

-- Política para admins (control completo)
CREATE POLICY admin_full_products ON productos
  FOR ALL TO api_admin
  USING (true) WITH CHECK (true);

-- Tabla de listas de deseos
ALTER TABLE listas_deseos ENABLE ROW LEVEL SECURITY;

-- Política para dueños de listas
CREATE POLICY owner_list_access ON listas_deseos
  FOR ALL TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID)
  WITH CHECK (id_usuario = current_setting('app.current_user_id')::UUID);

-- Política para listas públicas
CREATE POLICY public_list_read ON listas_deseos
  FOR SELECT TO api_public
  USING (NOT es_privada);

-- Tabla de carritos de compra
ALTER TABLE carritos_compras ENABLE ROW LEVEL SECURITY;

-- Política para dueños de carritos
CREATE POLICY owner_cart_access ON carritos_compras
  FOR ALL TO api_customer
  USING (id_usuario = current_setting('app.current_user_id')::UUID)
  WITH CHECK (id_usuario = current_setting('app.current_user_id')::UUID);

-- =============================================
-- SEGURIDAD PARA TABLAS DE AUDITORÍA
-- =============================================

-- Tabla historial_precios
ALTER TABLE historial_precios ENABLE ROW LEVEL SECURITY;

CREATE POLICY admin_read_price_history ON historial_precios
  FOR SELECT TO api_admin
  USING (true);

-- Tabla registro_inventario
ALTER TABLE registro_inventario ENABLE ROW LEVEL SECURITY;

CREATE POLICY admin_read_inventory_history ON registro_inventario
  FOR SELECT TO api_admin
  USING (true);

-- Tabla historial_estados_pedido
ALTER TABLE historial_estados_pedido ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_read_own_order_history ON historial_estados_pedido
  FOR SELECT TO api_customer
  USING (id_pedido IN (
    SELECT id_pedido FROM pedidos 
    WHERE id_usuario = current_setting('app.current_user_id')::UUID
  ));

CREATE POLICY admin_read_all_order_history ON historial_estados_pedido
  FOR SELECT TO api_admin
  USING (true);

CREATE POLICY delivery_read_assigned_order_history ON historial_estados_pedido
  FOR SELECT TO api_delivery
  USING (id_pedido IN (
    SELECT id_pedido FROM pedidos 
    WHERE id_estado IN (
      SELECT id_estado FROM estados_pedido 
      WHERE codigo_estado IN ('por_enviar', 'enviado')
    )
  ));