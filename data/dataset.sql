-- Inserción de datos para la base de datos de e-commerce

-- ROLES
INSERT INTO roles (nombre_rol, descripcion, permisos) VALUES
('administrador', 'Acceso total al sistema', '{"usuarios": ["leer", "escribir", "eliminar"], "productos": ["leer", "escribir", "eliminar"], "pedidos": ["leer", "escribir"]}'),
('editor', 'Puede gestionar productos y pedidos', '{"productos": ["leer", "escribir"], "pedidos": ["leer", "escribir"]}'),
('cliente', 'Acceso básico para comprar', '{"pedidos": ["leer", "crear"], "reseñas": ["leer", "crear"]}');

-- UBICACIONES (10 ubicaciones de ejemplo)
INSERT INTO ubicaciones (direccion, coordenadas) VALUES
('{"linea1": "Av. Larco 123", "distrito": "Miraflores", "provincia": "Lima", "departamento": "Lima", "codigo_postal": "15074", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-77.0282, -12.1214), 4326)),
('{"linea1": "Jr. de la Unión 456", "distrito": "Cercado de Lima", "provincia": "Lima", "departamento": "Lima", "codigo_postal": "15001", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-77.0311, -12.0464), 4326)),
('{"linea1": "Calle Arequipa 789", "distrito": "Yanahuara", "provincia": "Arequipa", "departamento": "Arequipa", "codigo_postal": "04013", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-71.5432, -16.3888), 4326)),
('{"linea1": "Av. El Sol 101", "distrito": "Cusco", "provincia": "Cusco", "departamento": "Cusco", "codigo_postal": "08002", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-71.9782, -13.5167), 4326)),
('{"linea1": "Calle Pizarro 234", "distrito": "Trujillo", "provincia": "Trujillo", "departamento": "La Libertad", "codigo_postal": "13001", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-79.0292, -8.1119), 4326)),
('{"linea1": "Av. Pardo 567", "distrito": "Iquitos", "provincia": "Maynas", "departamento": "Loreto", "codigo_postal": "16001", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-73.2538, -3.7491), 4326)),
('{"linea1": "Calle Real 890", "distrito": "Huancayo", "provincia": "Huancayo", "departamento": "Junín", "codigo_postal": "12001", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-75.2101, -12.0651), 4326)),
('{"linea1": "Av. Grau 111", "distrito": "Piura", "provincia": "Piura", "departamento": "Piura", "codigo_postal": "20001", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-80.6328, -5.1945), 4326)),
('{"linea1": "Jr. 28 de Julio 222", "distrito": "Pucallpa", "provincia": "Coronel Portillo", "departamento": "Ucayali", "codigo_postal": "25001", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-74.5539, -8.3791), 4326)),
('{"linea1": "Av. Balta 333", "distrito": "Chiclayo", "provincia": "Chiclayo", "departamento": "Lambayeque", "codigo_postal": "14001", "pais": "Peru"}', ST_SetSRID(ST_MakePoint(-79.8409, -6.7714), 4326));

-- USUARIOS (100 usuarios)
-- Nota: Las contraseñas son hashes de ejemplo. En un sistema real, usar bcrypt.
INSERT INTO usuarios (nombre_usuario, correo_electronico, contrasena_hash, nombres, apellidos, telefono, id_ubicacion_principal, id_rol)
SELECT
    'usuario' || i,
    'usuario' || i || '@example.com',
    'hash_contrasena_segura_' || i,
    'Nombre' || i,
    'Apellido' || i,
    '9' || LPAD(i::text, 8, '0'),
    (i % 10) + 1,
    CASE WHEN i <= 2 THEN 1 WHEN i <= 5 THEN 2 ELSE 3 END
FROM generate_series(1, 100) AS i;

-- CATEGORÍAS
INSERT INTO categorias (nombre, descripcion) VALUES
('Electrónica', 'Dispositivos y gadgets electrónicos'),
('Ropa', 'Prendas de vestir para todas las edades'),
('Hogar', 'Artículos para el hogar y decoración'),
('Libros', 'Libros de diversos géneros');

INSERT INTO categorias (nombre, id_categoria_padre, descripcion) VALUES
('Smartphones', 1, 'Teléfonos inteligentes y accesorios'),
('Laptops', 1, 'Computadoras portátiles de varias marcas'),
('Camisetas', 2, 'Camisetas de algodón y otros materiales'),
('Pantalones', 2, 'Pantalones casuales y de vestir');

-- DETALLES DE PRODUCTOS
INSERT INTO detalles_productos (tipo_producto, especificaciones, peso, dimensiones, material_principal) VALUES
('Smartphone', '{"pantalla": "6.5 pulgadas", "ram": "8GB", "almacenamiento": "128GB"}', 0.2, ARRAY[16, 8, 0.8], 'Aluminio'),
('Laptop', '{"procesador": "Intel Core i7", "ram": "16GB", "disco": "512GB SSD"}', 1.5, ARRAY[35, 25, 2], 'Plástico'),
('Camiseta', '{}', 0.3, ARRAY[70, 50, 0.5], 'Algodón');

-- PRODUCTOS (20 productos de ejemplo)
DO $$
DECLARE
    categoria_electronica INT;
    categoria_ropa INT;
    detalle_smartphone INT;
    detalle_laptop INT;
    detalle_camiseta INT;
BEGIN
    SELECT id_categoria INTO categoria_electronica FROM categorias WHERE nombre = 'Smartphones';
    SELECT id_categoria INTO categoria_ropa FROM categorias WHERE nombre = 'Camisetas';
    SELECT id_detalle_producto INTO detalle_smartphone FROM detalles_productos WHERE tipo_producto = 'Smartphone';
    SELECT id_detalle_producto INTO detalle_laptop FROM detalles_productos WHERE tipo_producto = 'Laptop';
    SELECT id_detalle_producto INTO detalle_camiseta FROM detalles_productos WHERE tipo_producto = 'Camiseta';

    INSERT INTO productos (codigo_sku, nombre, precio, costo, cantidad_disponible, id_categoria, id_detalle_producto, marca, atributos_generales) VALUES
    ('TEC-S23-001', 'Galaxy S23', 3499.90, 2800.00, 50, categoria_electronica, detalle_smartphone, 'Samsung', '{"color": "Negro", "garantia": "1 año"}'),
    ('TEC-I14-001', 'iPhone 14', 4299.90, 3500.00, 40, categoria_electronica, detalle_smartphone, 'Apple', '{"color": "Blanco", "garantia": "1 año"}'),
    ('TEC-LHP-001', 'HP Pavilion', 2999.90, 2400.00, 30, categoria_electronica, detalle_laptop, 'HP', '{"color": "Plata", "garantia": "2 años"}'),
    ('ROP-CAM-001', 'Camiseta Básica', 49.90, 25.00, 200, categoria_ropa, detalle_camiseta, 'Marca Local', '{"color": "Azul"}'),
    ('ROP-CAM-002', 'Camiseta Estampada', 69.90, 35.00, 150, categoria_ropa, detalle_camiseta, 'Marca Local', '{"color": "Gris"}');
END $$;

-- IMÁGENES DE PRODUCTOS
DO $$
DECLARE
    prod_id_1 UUID;
    prod_id_2 UUID;
BEGIN
    SELECT id_producto INTO prod_id_1 FROM productos WHERE codigo_sku = 'TEC-S23-001';
    SELECT id_producto INTO prod_id_2 FROM productos WHERE codigo_sku = 'ROP-CAM-001';

    INSERT INTO imagenes_productos (id_producto, url_imagen, texto_alternativo, es_principal) VALUES
    (prod_id_1, 'https://example.com/s23_principal.jpg', 'Vista frontal del Galaxy S23', TRUE),
    (prod_id_1, 'https://example.com/s23_trasera.jpg', 'Vista trasera del Galaxy S23', FALSE),
    (prod_id_2, 'https://example.com/camiseta_azul.jpg', 'Camiseta básica color azul', TRUE);
END $$;

-- ESTADOS DE PEDIDO
INSERT INTO estados_pedido (codigo_estado, nombre_estado, descripcion, es_final, orden_flujo) VALUES
('pendiente', 'Pendiente de Pago', 'El pedido ha sido creado pero no pagado.', FALSE, 1),
('procesando', 'En Proceso', 'El pago ha sido recibido y el pedido se está preparando.', FALSE, 2),
('enviado', 'Enviado', 'El pedido ha sido despachado.', FALSE, 3),
('entregado', 'Entregado', 'El pedido ha sido entregado al cliente.', TRUE, 4),
('cancelado', 'Cancelado', 'El pedido ha sido cancelado.', TRUE, 5);

-- MÉTODOS DE PAGO
INSERT INTO metodos_pago (nombre, descripcion, requiere_confirmacion, configuracion) VALUES
('tarjeta_credito', 'Pago con tarjeta de crédito o débito', FALSE, '{"pasarela": "Stripe"}'),
('yape_plin', 'Pago a través de Yape o Plin', TRUE, '{"numero_yape": "987654321"}'),
('pago_efectivo', 'Pago en agentes autorizados', TRUE, '{"empresa": "PagoEfectivo"}');

-- Se continuaría con la inserción de datos para el resto de las tablas (listas_deseos, carritos_compras, pedidos, etc.)
-- A continuación un ejemplo de cómo poblar la tabla de pedidos para los primeros 5 usuarios.

DO $$
DECLARE
    user_id UUID;
    prod_id_1 UUID;
    prod_id_2 UUID;
    pedido_id UUID;
    estado_procesando INT;
    metodo_tarjeta INT;
    user_location JSONB;
    i INT;
BEGIN
    SELECT id_producto INTO prod_id_1 FROM productos WHERE codigo_sku = 'TEC-S23-001';
    SELECT id_producto INTO prod_id_2 FROM productos WHERE codigo_sku = 'ROP-CAM-001';
    SELECT id_estado INTO estado_procesando FROM estados_pedido WHERE codigo_estado = 'procesando';
    SELECT id_metodo_pago INTO metodo_tarjeta FROM metodos_pago WHERE nombre = 'tarjeta_credito';

    FOR i IN 1..5 LOOP
        SELECT id_usuario, u.direccion INTO user_id, user_location
        FROM usuarios
        JOIN ubicaciones u ON usuarios.id_ubicacion_principal = u.id_ubicacion
        WHERE id_secuencial = i;

        pedido_id := gen_random_uuid();

        INSERT INTO pedidos (id_pedido, id_usuario, numero_pedido, id_estado, subtotal, impuestos, costo_envio, total, id_metodo_pago, estado_pago, direccion)
        VALUES (
            pedido_id,
            user_id,
            'PED-2025-000' || i,
            estado_procesando,
            3549.80,
            638.96, -- 18% IGV
            15.00,
            4203.76,
            metodo_tarjeta,
            TRUE,
            user_location
        );

        INSERT INTO items_pedido (id_pedido, id_producto, cantidad, precio_unitario, precio_total) VALUES
        (pedido_id, prod_id_1, 1, 3499.90, 3499.90),
        (pedido_id, prod_id_2, 1, 49.90, 49.90);
    END LOOP;
END $$;


-- RESEÑAS DE PRODUCTOS (Ejemplo)
DO $$
DECLARE
    user_id UUID;
    prod_id UUID;
BEGIN
    SELECT id_usuario INTO user_id FROM usuarios WHERE id_secuencial = 1;
    SELECT id_producto INTO prod_id FROM productos WHERE codigo_sku = 'TEC-S23-001';

    INSERT INTO resenas_productos (id_producto, id_usuario, calificacion, comentario, esta_aprobado)
    VALUES (prod_id, user_id, 5, '¡Excelente celular, muy rápido y la cámara es increíble!', TRUE);
END $$;
