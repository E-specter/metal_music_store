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