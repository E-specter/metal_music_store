-- Dataset de Pruebas para Metal Music Store Database
-- Ejecutar después de crear la estructura de la base de datos

-- ================================================================
-- INSERCIÓN DE DATOS DE PRUEBA
-- ================================================================

-- 1. ROLES
INSERT INTO roles (nombre_rol, descripcion, permisos) VALUES
('admin', 'Administrador del sistema', '{"usuarios": "full", "productos": "full", "pedidos": "full", "reportes": "full"}'),
('empleado', 'Empleado de la tienda', '{"productos": "read_write", "pedidos": "read_write", "inventario": "read_write"}'),
('cliente', 'Cliente registrado', '{"perfil": "read_write", "pedidos": "read", "wishlist": "full"}'),
('gerente', 'Gerente de tienda', '{"usuarios": "read", "productos": "full", "pedidos": "full", "reportes": "read"}');

-- 2. USUARIOS
INSERT INTO usuarios (nombre_usuario, correo_electronico, contrasena_hash, nombres, apellidos, telefono, direccion, id_rol, esta_activo, ultimo_acceso) VALUES
-- Administradores
('admin_metal', 'admin@metalstore.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Carlos', 'Administrador', '+51987654321', '{"calle": "Av. Metal 123", "distrito": "Miraflores", "ciudad": "Lima", "codigo_postal": "15074"}', 1, true, '2025-06-13 08:00:00'),

-- Empleados
('emp_juan', 'juan.vendedor@metalstore.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Juan Carlos', 'Vásquez Ruiz', '+51912345678', '{"calle": "Jr. Los Olivos 456", "distrito": "San Isidro", "ciudad": "Lima", "codigo_postal": "15073"}', 2, true, '2025-06-12 18:30:00'),
('emp_maria', 'maria.inventario@metalstore.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'María Elena', 'Sánchez Torres', '+51923456789', '{"calle": "Av. Universitaria 789", "distrito": "Los Olivos", "ciudad": "Lima", "codigo_postal": "15304"}', 2, true, '2025-06-13 09:15:00'),

-- Gerente
('ger_pedro', 'pedro.gerente@metalstore.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Pedro Miguel', 'Ramírez Castro', '+51934567890', '{"calle": "Av. Javier Prado 1012", "distrito": "San Borja", "ciudad": "Lima", "codigo_postal": "15036"}', 4, true, '2025-06-13 07:45:00'),

-- Clientes
('metalhead88', 'ricardo.fan@email.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Ricardo Andrés', 'Morales Díaz', '+51945678901', '{"calle": "Calle Las Begonias 234", "distrito": "San Isidro", "ciudad": "Lima", "codigo_postal": "15073"}', 3, true, '2025-06-13 10:20:00'),
('ironmaiden_fan', 'ana.rocker@email.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Ana Sofía', 'Guerrero López', '+51956789012', '{"calle": "Av. Arequipa 567", "distrito": "Lince", "ciudad": "Lima", "codigo_postal": "15046"}', 3, true, '2025-06-12 20:30:00'),
('blacksabbath_lover', 'miguel.metal@email.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Miguel Ángel', 'Fernández Ruiz', '+51967890123', '{"calle": "Jr. Camaná 890", "distrito": "Cercado de Lima", "ciudad": "Lima", "codigo_postal": "15001"}', 3, true, '2025-06-11 19:45:00'),
('thrash_warrior', 'lucia.headbanger@email.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Lucía Isabel', 'Mendoza Silva', '+51978901234', '{"calle": "Av. Brasil 345", "distrito": "Breña", "ciudad": "Lima", "codigo_postal": "15082"}', 3, true, '2025-06-13 11:10:00'),
('deathmetal_king', 'carlos.brutal@email.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Carlos Eduardo', 'Huamán Chávez', '+51989012345', '{"calle": "Calle Bolívar 678", "distrito": "Pueblo Libre", "ciudad": "Lima", "codigo_postal": "15084"}', 3, true, '2025-06-10 16:20:00'),
('power_metal_queen', 'sofia.symphonic@email.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Sofía Carmen', 'Vargas Pérez', '+51990123456', '{"calle": "Av. La Marina 901", "distrito": "San Miguel", "ciudad": "Lima", "codigo_postal": "15088"}', 3, true, '2025-06-13 14:30:00');

-- 3. CATEGORÍAS
INSERT INTO categorias (nombre, descripcion, id_categoria_padre, slug, esta_activo) VALUES
-- Categorías principales
('Ropa y Accesorios', 'Vestimenta y accesorios relacionados con el metal', NULL, 'ropa-accesorios', true),
('Música', 'Discos, vinilos y material musical', NULL, 'musica', true),
('Instrumentos', 'Instrumentos musicales y accesorios', NULL, 'instrumentos', true),
('Coleccionables', 'Artículos de colección y memorabilia', NULL, 'coleccionables', true),

-- Subcategorías de Ropa
('Camisetas', 'Camisetas de bandas de metal', 1, 'camisetas', true),
('Sudaderas', 'Hoodies y sudaderas', 1, 'sudaderas', true),
('Chaquetas', 'Chaquetas de cuero y denim', 1, 'chaquetas', true),
('Accesorios', 'Cinturones, pulseras, collares', 1, 'accesorios-ropa', true),

-- Subcategorías de Música
('CDs', 'Discos compactos originales', 2, 'cds', true),
('Vinilos', 'Discos de vinilo', 2, 'vinilos', true),
('Cassettes', 'Cintas de cassette', 2, 'cassettes', true),

-- Subcategorías de Instrumentos
('Guitarras', 'Guitarras eléctricas y acústicas', 3, 'guitarras', true),
('Bajos', 'Bajos eléctricos', 3, 'bajos', true),
('Baterías', 'Sets de batería y accesorios', 3, 'baterias', true),
('Amplificadores', 'Amplificadores y cabezales', 3, 'amplificadores', true);

-- 4. PRODUCTOS
INSERT INTO productos (codigo_sku, nombre, descripcion, precio, costo, cantidad_disponible, id_categoria, marca, talla, material, peso, esta_activo, atributos) VALUES
-- Camisetas
('TSH-METALLICA-001', 'Camiseta Metallica Master of Puppets', 'Camiseta oficial de Metallica con diseño del álbum Master of Puppets', 75.00, 35.00, 25, 5, 'Metallica Official', 'M', 'Algodón 100%', 0.25, true, '{"banda": "Metallica", "album": "Master of Puppets", "año": "1986", "color": "negro"}'),
('TSH-IRONMAIDEN-001', 'Camiseta Iron Maiden Number of the Beast', 'Camiseta oficial de Iron Maiden con el icónico diseño de Eddie', 80.00, 38.00, 18, 5, 'Iron Maiden Official', 'L', 'Algodón 100%', 0.25, true, '{"banda": "Iron Maiden", "album": "The Number of the Beast", "año": "1982", "color": "negro"}'),
('TSH-SABBATH-001', 'Camiseta Black Sabbath Paranoid', 'Camiseta clásica de Black Sabbath del álbum Paranoid', 70.00, 32.00, 30, 5, 'Black Sabbath Official', 'S', 'Algodón 100%', 0.24, true, '{"banda": "Black Sabbath", "album": "Paranoid", "año": "1970", "color": "negro"}'),
('TSH-SLAYER-001', 'Camiseta Slayer Reign in Blood', 'Camiseta de Slayer con diseño del álbum Reign in Blood', 75.00, 35.00, 22, 5, 'Slayer Official', 'XL', 'Algodón 100%', 0.26, true, '{"banda": "Slayer", "album": "Reign in Blood", "año": "1986", "color": "rojo"}'),

-- Sudaderas
('HOD-MEGADETH-001', 'Sudadera Megadeth Peace Sells', 'Sudadera con capucha de Megadeth del álbum Peace Sells', 120.00, 65.00, 15, 6, 'Megadeth Official', 'L', 'Algodón 80% Poliéster 20%', 0.65, true, '{"banda": "Megadeth", "album": "Peace Sells", "color": "gris", "capucha": true}'),
('HOD-PANTERA-001', 'Sudadera Pantera Cowboys From Hell', 'Sudadera oficial de Pantera con logo clásico', 125.00, 68.00, 12, 6, 'Pantera Official', 'M', 'Algodón 80% Poliéster 20%', 0.68, true, '{"banda": "Pantera", "album": "Cowboys From Hell", "color": "negro", "capucha": true}'),

-- Chaquetas
('JKT-LEATHER-001', 'Chaqueta de Cuero Estilo Metalero', 'Chaqueta de cuero genuino estilo biker con tachas', 450.00, 280.00, 8, 7, 'Metal Gear', 'L', 'Cuero genuino', 1.50, true, '{"estilo": "biker", "tachas": true, "cremalleras": "múltiples", "color": "negro"}'),
('JKT-DENIM-001', 'Chaqueta Denim Battle Jacket', 'Chaqueta de mezclilla perfecta para parches de bandas', 180.00, 95.00, 20, 7, 'Metal Works', 'M', 'Denim 100%', 0.85, true, '{"material": "denim", "lavado": "stonewash", "bolsillos": 4, "color": "azul oscuro"}'),

-- CDs
('CD-METALLICA-001', 'CD Metallica - Master of Puppets (Remaster)', 'Álbum remasterizado de Metallica Master of Puppets', 45.00, 22.00, 35, 9, 'Elektra Records', NULL, NULL, 0.10, true, '{"formato": "CD", "año_original": "1986", "remasterizado": true, "bonus_tracks": true}'),
('CD-IRONMAIDEN-001', 'CD Iron Maiden - The Number of the Beast', 'Álbum clásico de Iron Maiden remasterizado', 45.00, 22.00, 28, 9, 'EMI Records', NULL, NULL, 0.10, true, '{"formato": "CD", "año_original": "1982", "remasterizado": true, "bonus_tracks": false}'),
('CD-SABBATH-001', 'CD Black Sabbath - Paranoid', 'Álbum fundacional del heavy metal', 40.00, 20.00, 40, 9, 'Vertigo Records', NULL, NULL, 0.10, true, '{"formato": "CD", "año_original": "1970", "remasterizado": true, "historico": true}'),

-- Vinilos
('VNL-METALLICA-001', 'Vinilo Metallica - Master of Puppets (180g)', 'Vinilo de 180 gramos del clásico álbum de Metallica', 120.00, 65.00, 15, 10, 'Elektra Records', NULL, NULL, 0.35, true, '{"formato": "LP", "peso": "180g", "velocidad": "33 RPM", "color": "negro"}'),
('VNL-MAIDEN-001', 'Vinilo Iron Maiden - Powerslave (Picture Disc)', 'Vinilo picture disc del álbum Powerslave', 150.00, 78.00, 10, 10, 'EMI Records', NULL, NULL, 0.35, true, '{"formato": "LP", "tipo": "picture disc", "velocidad": "33 RPM", "edicion_limitada": true}'),

-- Guitarras
('GTR-GIBSON-001', 'Guitarra Gibson Les Paul Studio', 'Guitarra eléctrica Gibson Les Paul Studio perfecta para metal', 2800.00, 1800.00, 3, 12, 'Gibson', NULL, 'Caoba', 4.50, true, '{"tipo": "electrica", "pastillas": "humbucker", "cuerdas": 6, "color": "cherry sunburst"}'),
('GTR-JACKSON-001', 'Guitarra Jackson Dinky JS32', 'Guitarra eléctrica Jackson ideal para metal y shred', 850.00, 520.00, 5, 12, 'Jackson', NULL, 'Tilo', 3.20, true, '{"tipo": "electrica", "pastillas": "humbucker", "cuerdas": 6, "color": "negro mate"}'),

-- Bajos
('BSS-FENDER-001', 'Bajo Fender Player Precision Bass', 'Bajo eléctrico Fender Precision Bass de 4 cuerdas', 1200.00, 750.00, 4, 13, 'Fender', NULL, 'Aliso', 4.20, true, '{"tipo": "electrico", "cuerdas": 4, "pastillas": "precision", "color": "sunburst"}'),

-- Amplificadores
('AMP-MARSHALL-001', 'Amplificador Marshall DSL40CR', 'Amplificador Marshall de 40W perfecto para metal', 1800.00, 1200.00, 6, 15, 'Marshall', NULL, NULL, 18.50, true, '{"potencia": "40W", "valvulas": true, "canales": 2, "efectos": "reverb"}'),

-- Accesorios
('ACC-BELT-001', 'Cinturón con Tachas Pirámide', 'Cinturón de cuero con tachas piramidales', 85.00, 40.00, 25, 8, 'Metal Gear', 'Ajustable', 'Cuero', 0.45, true, '{"tachas": "piramidales", "ancho": "4cm", "color": "negro"}'),
('ACC-NECKLACE-001', 'Collar Pentagrama Acero Inoxidable', 'Collar con colgante de pentagrama en acero inoxidable', 65.00, 30.00, 30, 8, 'Metal Jewelry', NULL, 'Acero inoxidable', 0.08, true, '{"simbolo": "pentagrama", "cadena": "60cm", "material": "acero inoxidable"}'),

-- Coleccionables
('COL-FIGURE-001', 'Figura Eddie Iron Maiden 20cm', 'Figura coleccionable de Eddie, mascota de Iron Maiden', 180.00, 90.00, 12, 4, 'NECA', NULL, 'PVC', 0.50, true, '{"personaje": "Eddie", "altura": "20cm", "articulada": true, "edicion_limitada": false}'),
('COL-POSTER-001', 'Poster Vintage Metallica Kill Em All', 'Poster vintage original del álbum Kill Em All', 120.00, 60.00, 8, 4, 'Original Posters', NULL, 'Papel', 0.05, true, '{"tamaño": "60x90cm", "año": "1983", "condicion": "mint", "enmarcado": false}');

-- 5. IMÁGENES DE PRODUCTOS
INSERT INTO imagenes_productos (id_producto, url_imagen, texto_alternativo, es_principal, orden_visualizacion) VALUES
-- Camiseta Metallica
(1, '/images/productos/tsh-metallica-001-front.jpg', 'Camiseta Metallica Master of Puppets - Frente', true, 1),
(1, '/images/productos/tsh-metallica-001-back.jpg', 'Camiseta Metallica Master of Puppets - Espalda', false, 2),
(1, '/images/productos/tsh-metallica-001-detail.jpg', 'Detalle del diseño Master of Puppets', false, 3),

-- Camiseta Iron Maiden
(2, '/images/productos/tsh-ironmaiden-001-front.jpg', 'Camiseta Iron Maiden Number of the Beast - Frente', true, 1),
(2, '/images/productos/tsh-ironmaiden-001-back.jpg', 'Camiseta Iron Maiden Number of the Beast - Espalda', false, 2),

-- Guitarra Gibson
(13, '/images/productos/gtr-gibson-001-front.jpg', 'Gibson Les Paul Studio - Vista frontal', true, 1),
(13, '/images/productos/gtr-gibson-001-back.jpg', 'Gibson Les Paul Studio - Vista posterior', false, 2),
(13, '/images/productos/gtr-gibson-001-headstock.jpg', 'Gibson Les Paul Studio - Clavijero', false, 3),
(13, '/images/productos/gtr-gibson-001-detail.jpg', 'Gibson Les Paul Studio - Detalles', false, 4);

-- 6. LISTAS DE DESEOS
INSERT INTO listas_deseos (id_usuario, nombre, es_privada) VALUES
(5, 'Mi Lista Principal', false),
(6, 'Próximas Compras', true),
(7, 'Colección de Vinilos', false),
(8, 'Equipamiento Musical', true),
(9, 'Wishlist Metal', false);

-- 7. ITEMS EN LISTAS DE DESEOS
INSERT INTO items_lista_deseos (id_lista_deseos, id_producto) VALUES
(1, 1), (1, 13), (1, 17), -- metalhead88: Metallica, Gibson, Marshall
(2, 2), (2, 9), (2, 11),  -- ironmaiden_fan: Iron Maiden, CD Metallica, Vinilo Metallica
(3, 10), (3, 12), (3, 3), -- blacksabbath_lover: Vinilos
(4, 13), (4, 14), (4, 17), -- thrash_warrior: Guitarras y amp
(5, 5), (5, 6), (5, 18);   -- power_metal_queen: Sudaderas y accesorios

-- 8. CARRITOS DE COMPRAS
INSERT INTO carritos_compras (id_usuario) VALUES
(5), (6), (7), (8), (9);

-- 9. ITEMS EN CARRITOS
INSERT INTO items_carrito (id_carrito, id_producto, cantidad) VALUES
(1, 1, 2), (1, 9, 1),     -- metalhead88: 2 camisetas Metallica, 1 CD
(2, 2, 1), (2, 18, 1),    -- ironmaiden_fan: 1 camiseta Iron Maiden, 1 cinturón
(3, 3, 1), (3, 10, 1),    -- blacksabbath_lover: 1 camiseta Sabbath, 1 vinilo
(4, 5, 1),                -- thrash_warrior: 1 sudadera
(5, 19, 2), (5, 20, 1);   -- power_metal_queen: 2 collares, 1 figura

-- 10. PEDIDOS
INSERT INTO pedidos (id_usuario, numero_pedido, estado, subtotal, impuestos, costo_envio, total, direccion_envio, direccion_facturacion, metodo_pago, estado_pago, notas) VALUES
('5', 'MTL-2025-0001', 'entregado', 195.00, 35.10, 15.00, 245.10, 
 '{"nombre": "Ricardo Andrés Morales Díaz", "calle": "Calle Las Begonias 234", "distrito": "San Isidro", "ciudad": "Lima", "codigo_postal": "15073", "telefono": "+51945678901"}',
 '{"nombre": "Ricardo Andrés Morales Díaz", "calle": "Calle Las Begonias 234", "distrito": "San Isidro", "ciudad": "Lima", "codigo_postal": "15073", "telefono": "+51945678901"}',
 'tarjeta_credito', 'pagado', 'Entrega rápida solicitada'),

('6', 'MTL-2025-0002', 'enviado', 125.00, 22.50, 10.00, 157.50,
 '{"nombre": "Ana Sofía Guerrero López", "calle": "Av. Arequipa 567", "distrito": "Lince", "ciudad": "Lima", "codigo_postal": "15046", "telefono": "+51956789012"}',
 '{"nombre": "Ana Sofía Guerrero López", "calle": "Av. Arequipa 567", "distrito": "Lince", "ciudad": "Lima", "codigo_postal": "15046", "telefono": "+51956789012"}',
 'transferencia_bancaria', 'pagado', NULL),

('7', 'MTL-2025-0003', 'procesando', 285.00, 51.30, 20.00, 356.30,
 '{"nombre": "Miguel Ángel Fernández Ruiz", "calle": "Jr. Camaná 890", "distrito": "Cercado de Lima", "ciudad": "Lima", "codigo_postal": "15001", "telefono": "+51967890123"}',
 '{"nombre": "Miguel Ángel Fernández Ruiz", "calle": "Jr. Camaná 890", "distrito": "Cercado de Lima", "ciudad": "Lima", "codigo_postal": "15001", "telefono": "+51967890123"}',
 'paypal', 'pagado', 'Cliente frecuente - aplicar descuento próxima compra'),

('8', 'MTL-2025-0004', 'pendiente', 2800.00, 504.00, 25.00, 3329.00,
 '{"nombre": "Lucía Isabel Mendoza Silva", "calle": "Av. Brasil 345", "distrito": "Breña", "ciudad": "Lima", "codigo_postal": "15082", "telefono": "+51978901234"}',
 '{"nombre": "Lucía Isabel Mendoza Silva", "calle": "Av. Brasil 345", "distrito": "Breña", "ciudad": "Lima", "codigo_postal": "15082", "telefono": "+51978901234"}',
 'tarjeta_credito', 'pendiente', 'Verificar disponibilidad antes del envío'),

('9', 'MTL-2025-0005', 'cancelado', 380.00, 68.40, 15.00, 463.40,
 '{"nombre": "Carlos Eduardo Huamán Chávez", "calle": "Calle Bolívar 678", "distrito": "Pueblo Libre", "ciudad": "Lima", "codigo_postal": "15084", "telefono": "+51989012345"}',
 '{"nombre": "Carlos Eduardo Huamán Chávez", "calle": "Calle Bolívar 678", "distrito": "Pueblo Libre", "ciudad": "Lima", "codigo_postal": "15084", "telefono": "+51989012345"}',
 'tarjeta_debito', 'reembolsado', 'Cliente solicitó cancelación - producto agotado');

-- 11. ITEMS DE PEDIDOS
INSERT INTO items_pedido (id_pedido, id_producto, cantidad, precio_unitario, precio_total, descuento) VALUES
-- Pedido 1 (entregado)
(1, 1, 2, 75.00, 150.00, 0.00),
(1, 9, 1, 45.00, 45.00, 0.00),

-- Pedido 2 (enviado)
(2, 2, 1, 80.00, 80.00, 0.00),
(2, 9, 1, 45.00, 45.00, 0.00),

-- Pedido 3 (procesando)
(3, 3, 1, 70.00, 70.00, 0.00),
(3, 7, 1, 180.00, 180.00, 0.00),
(3, 18, 1, 85.00, 85.00, 10.00),

-- Pedido 4 (pendiente)
(4, 13, 1, 2800.00, 2800.00, 0.00),

-- Pedido 5 (cancelado)
(5, 5, 1, 120.00, 120.00, 0.00),
(5, 11, 1, 120.00, 120.00, 0.00),
(5, 17, 1, 1800.00, 1800.00, 300.00);

-- 12. HISTORIAL DE PRECIOS
INSERT INTO historial_precios (id_producto, precio_anterior, precio_nuevo, modificado_por, razon_cambio) VALUES
(1, 70.00, 75.00, 1, 'Ajuste por inflación'),
(2, 75.00, 80.00, 1, 'Aumento de precio del proveedor'),
(13, 2500.00, 2800.00, 4, 'Precio sugerido por fabricante'),
(17, 1700.00, 1800.00, 4, 'Ajuste de precio premium'),
(5, 115.00, 120.00, 2, 'Ajuste estacional');

-- 13. REGISTRO DE INVENTARIO
INSERT INTO registro_inventario (id_producto, cambio_cantidad, nueva_cantidad, tipo_cambio, id_referencia, notas, modificado_por) VALUES
-- Compras iniciales
(1, 50, 50, 'reabastecimiento', NULL, 'Stock inicial de camisetas Metallica', 3),
(2, 30, 30, 'reabastecimiento', NULL, 'Stock inicial de camisetas Iron Maiden', 3),
(3, 40, 40, 'reabastecimiento', NULL, 'Stock inicial de camisetas Black Sabbath', 3),
(13, 5, 5, 'reabastecimiento', NULL, 'Stock inicial de guitarras Gibson', 3),
(17, 8, 8, 'reabastecimiento', NULL, 'Stock inicial de amplificadores Marshall', 3),

-- Ventas
(1, -2, 48, 'compra', 1, 'Venta pedido MTL-2025-0001', 2),
(9, -1, 34, 'compra', 1, 'Venta pedido MTL-2025-0001', 2),
(2, -1, 29, 'compra', 2, 'Venta pedido MTL-2025-0002', 2),
(9, -1, 33, 'compra', 2, 'Venta pedido MTL-2025-0002', 2),

-- Ajustes
(1, -23, 25, 'ajuste', NULL, 'Ajuste de inventario tras conteo físico', 3),
(2, -11, 18, 'ajuste', NULL, 'Ajuste de inventario tras conteo físico', 3),
(3, -10, 30, 'ajuste', NULL, 'Ajuste de inventario tras conteo físico', 3),

-- Devoluciones
(5, 1, 13, 'devolucion', 5, 'Devolución pedido cancelado MTL-2025-0005', 2),
(11, 1, 11, 'devolucion', 5, 'Devolución pedido cancelado MTL-2025-0005', 2),

-- Daños
(18, -2, 23, 'daño', NULL, 'Cinturones dañados en transporte', 3),
(19, -1, 29, 'daño', NULL, 'Collar defectuoso detectado en control de calidad', 3);

-- 14. RESEÑAS DE PRODUCTOS
INSERT INTO reseñas_productos (id_producto, id_usuario, calificacion, titulo, comentario, esta_aprobada) VALUES
(1, 5, 5, 'Excelente calidad!', 'La camiseta de Metallica es de muy buena calidad, el diseño está perfectamente impreso y la tela es suave. Definitivamente recomendada para cualquier fan del metal.', true),
(1, 6, 4, 'Muy buena pero talla pequeña', 'Me encanta el diseño de Master of Puppets, pero la talla M me queda un poco ajustada. Recomiendo pedir una talla más grande.', true),
(2, 7, 5, 'Iron Maiden perfecto', 'Como fan de Iron Maiden desde hace 20 años, puedo decir que esta camiseta es auténtica y de gran calidad. El diseño de Eddie es impresionante.', true),
(3, 8, 4, 'Clásico atemporal', 'Black Sabbath siempre será legendario. La camiseta es buena, aunque esperaba que fuera un poco más gruesa la tela.', true),
(9, 5, 5, 'CD impecable', 'El CD llegó en perfectas condiciones, el sonido remasterizado es increíble. Vale cada sol pagado.', true),
(9, 6, 5, 'Master of Puppets remasterizado', 'Una joya para cualquier colección. El sonido es cristalino y las bonus tracks son geniales.', true),
(11, 7, 5, 'Vinilo excepcional', 'El vinilo de 180 gramos suena espectacular. La presentación es de primera y llegó muy bien empaquetado.', true),
(13, 8, 5, 'Gibson Les Paul increíble', 'Esta guitarra es una bestia para tocar metal. Los humbuckers suenan potentes y la construcción es sólida. Definitivamente vale la inversión.', true),
(17, 8, 4, 'Amplificador Marshall excelente', 'El Marshall DSL40CR tiene un sonido brutal para metal. Las válvulas le dan ese tono cálido característico. Solo le falta un poco más de potencia para venues grandes.', true),
(18, 9, 3, 'Cinturón regular', 'El cinturón está bien pero las tachas se sienten un poco frágiles. Por el precio esperaba mejor calidad en los herrajes.', true),
(20, 9, 5, 'Figura de Eddie perfecta', 'La figura de Eddie está increíblemente detallada. Es perfecta para cualquier fan de Iron Maiden. La calidad de NECA es excepcional.', true);

-- ================================================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA DE TIMESTAMPS
-- ================================================================

-- Trigger para usuarios
CREATE TRIGGER trigger_actualizar_fecha_usuarios
    BEFORE UPDATE ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_actualizacion();

-- Trigger para productos
CREATE TRIGGER trigger_actualizar_fecha_productos
    BEFORE UPDATE ON productos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_actualizacion();

-- Trigger para pedidos
CREATE TRIGGER trigger_actualizar_fecha_pedidos
    BEFORE UPDATE ON pedidos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_actualizacion();

-- Trigger para categorías
CREATE TRIGGER trigger_actualizar_fecha_categorias
    BEFORE UPDATE ON categorias
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_actualizacion();

-- Trigger para listas de deseos
CREATE TRIGGER trigger_actualizar_fecha_listas_deseos
    BEFORE UPDATE ON listas_deseos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_actualizacion();

-- Trigger para carritos
CREATE TRIGGER trigger_actualizar_fecha_carritos
    BEFORE UPDATE ON carritos_compras
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_actualizacion();

-- Trigger para reseñas
CREATE TRIGGER trigger_actualizar_fecha_reseñas
    BEFORE UPDATE ON reseñas_productos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_actualizacion();

-- Trigger para roles
CREATE TRIGGER trigger_actualizar_fecha_roles
    BEFORE UPDATE ON roles
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_actualizacion();

-- ================================================================
-- FUNCIONES Y PROCEDIMIENTOS PARA PRUEBAS
-- ================================================================

-- Función para obtener productos más vendidos
CREATE OR REPLACE FUNCTION obtener_productos_mas_vendidos(limite INTEGER DEFAULT 10)
RETURNS TABLE (
    id_producto INTEGER,
    nombre_producto VARCHAR(255),
    total_vendido BIGINT,
    ingresos_totales NUMERIC
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        p.id_producto,
        p.nombre,
        SUM(ip.cantidad) as total_vendido,
        SUM(ip.precio_total) as ingresos_totales
    FROM productos p
    JOIN items_pedido ip ON p.id_producto = ip.id_producto
    JOIN pedidos ped ON ip.id_pedido = ped.id_pedido
    WHERE ped.estado IN ('entregado', 'enviado')
    GROUP BY p.id_producto, p.nombre
    ORDER BY total_vendido DESC
    LIMIT limite;
END;
$ LANGUAGE plpgsql;

-- Función para obtener estadísticas de inventario
CREATE OR REPLACE FUNCTION obtener_estadisticas_inventario()
RETURNS TABLE (
    productos_total INTEGER,
    productos_bajo_stock INTEGER,
    productos_sin_stock INTEGER,
    valor_total_inventario NUMERIC
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as productos_total,
        COUNT(CASE WHEN cantidad_disponible <= 5 AND cantidad_disponible > 0 THEN 1 END)::INTEGER as productos_bajo_stock,
        COUNT(CASE WHEN cantidad_disponible = 0 THEN 1 END)::INTEGER as productos_sin_stock,
        SUM(cantidad_disponible * precio) as valor_total_inventario
    FROM productos 
    WHERE esta_activo = true;
END;
$ LANGUAGE plpgsql;

-- Función para obtener pedidos por estado
CREATE OR REPLACE FUNCTION obtener_pedidos_por_estado()
RETURNS TABLE (
    estado VARCHAR(20),
    cantidad_pedidos BIGINT,
    monto_total NUMERIC
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        p.estado,
        COUNT(*) as cantidad_pedidos,
        SUM(p.total) as monto_total
    FROM pedidos p
    GROUP BY p.estado
    ORDER BY cantidad_pedidos DESC;
END;
$ LANGUAGE plpgsql;

-- Función para buscar productos por texto
CREATE OR REPLACE FUNCTION buscar_productos(texto_busqueda TEXT)
RETURNS TABLE (
    id_producto INTEGER,
    codigo_sku VARCHAR(50),
    nombre VARCHAR(255),
    precio DECIMAL(10,2),
    cantidad_disponible INTEGER,
    categoria VARCHAR(100)
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        p.id_producto,
        p.codigo_sku,
        p.nombre,
        p.precio,
        p.cantidad_disponible,
        c.nombre as categoria
    FROM productos p
    LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
    WHERE p.esta_activo = true
    AND (
        p.nombre ILIKE '%' || texto_busqueda || '%'
        OR p.descripcion ILIKE '%' || texto_busqueda || '%'
        OR p.marca ILIKE '%' || texto_busqueda || '%'
        OR c.nombre ILIKE '%' || texto_busqueda || '%'
    )
    ORDER BY p.nombre;
END;
$ LANGUAGE plpgsql;

-- Procedimiento para actualizar inventario después de una venta
CREATE OR REPLACE FUNCTION actualizar_inventario_venta()
RETURNS TRIGGER AS $
BEGIN
    -- Solo actualizar si el pedido cambia a 'entregado'
    IF NEW.estado = 'entregado' AND OLD.estado != 'entregado' THEN
        -- Actualizar inventario para cada producto del pedido
        UPDATE productos 
        SET cantidad_disponible = cantidad_disponible - ip.cantidad
        FROM items_pedido ip
        WHERE productos.id_producto = ip.id_producto 
        AND ip.id_pedido = NEW.id_pedido;
        
        -- Registrar movimientos de inventario
        INSERT INTO registro_inventario (id_producto, cambio_cantidad, nueva_cantidad, tipo_cambio, id_referencia, notas)
        SELECT 
            ip.id_producto,
            -ip.cantidad,
            p.cantidad_disponible,
            'compra',
            NEW.id_pedido,
            'Venta confirmada - Pedido ' || NEW.numero_pedido
        FROM items_pedido ip
        JOIN productos p ON ip.id_producto = p.id_producto
        WHERE ip.id_pedido = NEW.id_pedido;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Crear trigger para actualización automática de inventario
CREATE TRIGGER trigger_actualizar_inventario_venta
    AFTER UPDATE ON pedidos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_inventario_venta();

-- ================================================================
-- VIEWS ÚTILES PARA REPORTES Y CONSULTAS
-- ================================================================

-- Vista de productos con información completa
CREATE VIEW vista_productos_completa AS
SELECT 
    p.id_producto,
    p.codigo_sku,
    p.nombre,
    p.descripcion,
    p.precio,
    p.cantidad_disponible,
    c.nombre as categoria,
    c.slug as categoria_slug,
    p.marca,
    p.esta_activo,
    p.fecha_creacion,
    p.fecha_actualizacion,
    COALESCE(avg_rating.promedio_calificacion, 0) as promedio_calificacion,
    COALESCE(avg_rating.total_reseñas, 0) as total_reseñas,
    img.url_imagen as imagen_principal
FROM productos p
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN (
    SELECT 
        id_producto, 
        AVG(calificacion::DECIMAL) as promedio_calificacion,
        COUNT(*) as total_reseñas
    FROM reseñas_productos 
    WHERE esta_aprobada = true
    GROUP BY id_producto
) avg_rating ON p.id_producto = avg_rating.id_producto
LEFT JOIN (
    SELECT DISTINCT ON (id_producto) 
        id_producto, 
        url_imagen
    FROM imagenes_productos 
    WHERE es_principal = true
    ORDER BY id_producto, orden_visualizacion
) img ON p.id_producto = img.id_producto;

-- Vista de pedidos con información del cliente
CREATE VIEW vista_pedidos_completa AS
SELECT 
    p.id_pedido,
    p.numero_pedido,
    p.estado,
    p.estado_pago,
    p.subtotal,
    p.impuestos,
    p.costo_envio,
    p.total,
    u.nombre_usuario,
    u.nombres,
    u.apellidos,
    u.correo_electronico,
    p.fecha_creacion,
    p.fecha_actualizacion,
    COUNT(ip.id_item_pedido) as total_items
FROM pedidos p
JOIN usuarios u ON p.id_usuario = u.id_usuario
LEFT JOIN items_pedido ip ON p.id_pedido = ip.id_pedido
GROUP BY p.id_pedido, u.id_usuario, u.nombre_usuario, u.nombres, u.apellidos, u.correo_electronico;

-- Vista de inventario con alertas
CREATE VIEW vista_inventario_alertas AS
SELECT 
    p.id_producto,
    p.codigo_sku,
    p.nombre,
    p.cantidad_disponible,
    p.precio,
    c.nombre as categoria,
    CASE 
        WHEN p.cantidad_disponible = 0 THEN 'SIN_STOCK'
        WHEN p.cantidad_disponible <= 5 THEN 'STOCK_BAJO'
        WHEN p.cantidad_disponible <= 10 THEN 'STOCK_MEDIO'
        ELSE 'STOCK_OK'
    END as estado_stock,
    p.cantidad_disponible * p.precio as valor_inventario
FROM productos p
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
WHERE p.esta_activo = true
ORDER BY p.cantidad_disponible ASC;

-- ================================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ================================================================

-- Índices para búsquedas frecuentes
CREATE INDEX idx_productos_nombre ON productos USING gin(to_tsvector('spanish', nombre));
CREATE INDEX idx_productos_descripcion ON productos USING gin(to_tsvector('spanish', descripcion));
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_activo ON productos(esta_activo);
CREATE INDEX idx_productos_cantidad ON productos(cantidad_disponible);

-- Índices para pedidos
CREATE INDEX idx_pedidos_usuario ON pedidos(id_usuario);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_creacion);
CREATE INDEX idx_pedidos_numero ON pedidos(numero_pedido);

-- Índices para usuarios
CREATE INDEX idx_usuarios_correo ON usuarios(correo_electronico);
CREATE INDEX idx_usuarios_activo ON usuarios(esta_activo);
CREATE INDEX idx_usuarios_rol ON usuarios(id_rol);

-- Índices para reseñas
CREATE INDEX idx_reseñas_producto ON reseñas_productos(id_producto);
CREATE INDEX idx_reseñas_aprobada ON reseñas_productos(esta_aprobada);
CREATE INDEX idx_reseñas_calificacion ON reseñas_productos(calificacion);

-- ================================================================
-- DATOS ADICIONALES PARA PRUEBAS DE ESTRÉS
-- ================================================================

-- Insertar más productos para pruebas de rendimiento
INSERT INTO productos (codigo_sku, nombre, descripcion, precio, costo, cantidad_disponible, id_categoria, marca, esta_activo) VALUES
-- Más camisetas
('TSH-JUDAS-001', 'Camiseta Judas Priest British Steel', 'Camiseta oficial de Judas Priest', 75.00, 35.00, 20, 5, 'Judas Priest Official', true),
('TSH-MAIDEN-002', 'Camiseta Iron Maiden Fear of the Dark', 'Camiseta con diseño del álbum Fear of the Dark', 80.00, 38.00, 15, 5, 'Iron Maiden Official', true),
('TSH-OZZY-001', 'Camiseta Ozzy Osbourne Bark at the Moon', 'Camiseta clásica de Ozzy Osbourne', 75.00, 35.00, 25, 5, 'Ozzy Official', true),
('TSH-MAIDEN-003', 'Camiseta Iron Maiden Trooper', 'Camiseta con diseño de The Trooper', 80.00, 38.00, 30, 5, 'Iron Maiden Official', true),
('TSH-MOTORHEAD-001', 'Camiseta Motörhead Ace of Spades', 'Camiseta con el icónico diseño de Ace of Spades', 75.00, 35.00, 18, 5, 'Motörhead Official', true),

-- Más CDs
('CD-JUDAS-001', 'CD Judas Priest - British Steel', 'Álbum clásico de Judas Priest', 45.00, 22.00, 30, 9, 'Columbia Records', true),
('CD-OZZY-001', 'CD Ozzy Osbourne - Blizzard of Ozz', 'Primer álbum solista de Ozzy', 45.00, 22.00, 25, 9, 'Jet Records', true),
('CD-MOTORHEAD-001', 'CD Motörhead - Ace of Spades', 'Álbum legendario de Motörhead', 45.00, 22.00, 20, 9, 'Bronze Records', true),

-- Más accesorios
('ACC-PATCH-001', 'Parche Bordado Metallica Logo', 'Parche bordado oficial de Metallica', 25.00, 12.00, 50, 8, 'Metallica Official', true),
('ACC-PATCH-002', 'Parche Bordado Iron Maiden Eddie', 'Parche bordado de Eddie de Iron Maiden', 25.00, 12.00, 45, 8, 'Iron Maiden Official', true),
('ACC-KEYCHAIN-001', 'Llavero Metálico Slayer Logo', 'Llavero de metal con logo de Slayer', 35.00, 18.00, 40, 8, 'Slayer Official', true);

-- Más usuarios para pruebas
INSERT INTO usuarios (nombre_usuario, correo_electronico, contrasena_hash, nombres, apellidos, telefono, direccion, id_rol, esta_activo) VALUES
('test_user_01', 'test01@metalstore.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Usuario', 'Prueba 01', '+51900000001', '{"calle": "Test Street 01", "distrito": "Test", "ciudad": "Lima", "codigo_postal": "15001"}', 3, true),
('test_user_02', 'test02@metalstore.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Usuario', 'Prueba 02', '+51900000002', '{"calle": "Test Street 02", "distrito": "Test", "ciudad": "Lima", "codigo_postal": "15002"}', 3, true),
('test_user_03', 'test03@metalstore.com', '$2b$12$LQv3c1yqBwrOOsNJP3NQZO.aJ3pBw9nOyRzC5S7zRzOyRzC5S7zRz', 'Usuario', 'Prueba 03', '+51900000003', '{"calle": "Test Street 03", "distrito": "Test", "ciudad": "Lima", "codigo_postal": "15003"}', 3, true);