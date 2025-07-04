DELIMITER // CREATE PROCEDURE ObtenerFechasCategorias() BEGIN
SELECT id AS categoria_id,
  name AS nombre_categoria,
  created_at AS fecha_creacion,
  updated_at AS fecha_actualizacion
FROM categories;
END // DELIMITER;
“ products ” Fecha de creación y actualización DELIMITER // CREATE PROCEDURE ObtenerFechasProductos() BEGIN
SELECT id AS producto_id,
  name AS nombre_producto,
  created_at AS fecha_creacion,
  updated_at AS fecha_actualizacion
FROM products;
END // DELIMITER;
“ sales ” fecha de venta DELIMITER // CREATE PROCEDURE ObtenerFechasVentas() BEGIN
SELECT id AS venta_id,
  sale_date AS fecha_venta,
  created_at AS fecha_creacion,
  updated_at AS fecha_actualizacion
FROM sales;
END // DELIMITER;
product_movements – Fecha del movimiento DELIMITER // CREATE PROCEDURE ObtenerFechasMovimientosProductos() BEGIN
SELECT id AS movimiento_id,
  movement_date AS fecha_movimiento,
  created_at AS fecha_creacion,
  updated_at AS fecha_actualizacion
FROM product_movements;
END // DELIMITER;
inventories – Fechas de inventario DELIMITER // CREATE PROCEDURE ObtenerFechasInventario() BEGIN
SELECT id AS inventario_id,
  created_at AS fecha_creacion,
  updated_at AS fecha_actualizacion
FROM inventories;
END // DELIMITER;
purchases – Fechas de compra DELIMITER // CREATE PROCEDURE ObtenerFechasCompras() BEGIN
SELECT id AS compra_id,
  purchase_date AS fecha_compra,
  created_at AS fecha_creacion,
  updated_at AS fecha_actualizacion
FROM purchases;
END // DELIMITER;
returns – Fechas de devoluciones DELIMITER // CREATE PROCEDURE ObtenerFechasDevoluciones() BEGIN
SELECT id AS devolucion_id,
  return_date AS fecha_devolucion,
  created_at AS fecha_creacion,
  updated_at AS fecha_actualizacion
FROM returns;
END // DELIMITER;
Buscar una venta por fecha específica DELIMITER // CREATE PROCEDURE BuscarVentaPorFecha(IN fecha_param DATE) BEGIN
SELECT id AS venta_id,
  sale_date AS fecha_venta,
  total,
  created_at
FROM sales
WHERE sale_date = fecha_param;
END // DELIMITER;
--PARA ACTUALIZAR UN PRODUCTO:
DELIMITER $$ CREATE PROCEDURE actualizar_producto (
  IN _id_producto INT,
  IN _nombre VARCHAR(255),
  IN _descripcion TEXT,
  IN _precio DECIMAL(10, 2),
  IN _costo DECIMAL(10, 2),
  IN _cantidad_disponible INT,
  IN _id_categoria INT,
  IN _marca VARCHAR(100),
  IN _talla VARCHAR(50),
  IN _material VARCHAR(100),
  IN _peso DECIMAL(10, 2),
  IN _atributos JSON
) BEGIN
UPDATE productos
SET nombre = _nombre,
  descripcion = _descripcion,
  precio = _precio,
  costo = _costo,
  cantidad_disponible = _cantidad_disponible,
  id_categoria = _id_categoria,
  marca = _marca,
  talla = _talla,
  material = _material,
  peso = _peso,
  atributos = _atributos,
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_producto = _id_producto;
END $$ DELIMITER;
--PARA DESACTIVAR UN PRODUCTO:
DELIMITER $$ CREATE PROCEDURE desactivar_producto(IN _id_producto INT) BEGIN
UPDATE productos
SET esta_activo = FALSE,
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_producto = _id_producto;
END $$ DELIMITER;
PARA AÑADIR CATEGORIA: DELIMITER $$ CREATE PROCEDURE agregar_categoria(
  IN _nombre VARCHAR(100),
  IN _descripcion TEXT,
  IN _id_categoria_padre INT,
  IN _slug VARCHAR(100)
) BEGIN
INSERT INTO categorias (nombre, descripcion, id_categoria_padre, slug)
VALUES (
    _nombre,
    _descripcion,
    _id_categoria_padre,
    _slug
  );
END $$ DELIMITER;
--PARA ACTUALIZAR CATEGORIA:
DELIMITER $$ CREATE PROCEDURE actualizar_categoria(
  IN _id_categoria INT,
  IN _nombre VARCHAR(100),
  IN _descripcion TEXT,
  IN _id_categoria_padre INT,
  IN _slug VARCHAR(100)
) BEGIN
UPDATE categorias
SET nombre = _nombre,
  descripcion = _descripcion,
  id_categoria_padre = _id_categoria_padre,
  slug = _slug,
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_categoria = _id_categoria;
END $$ DELIMITER;
--ACTUALIZAR_USUARIO(...) PERMITE ACTUALIZAR DATOS DEL USUARIO (EXCEPTO CONTRASEÑA).
CREATE OR REPLACE PROCEDURE actualizar_usuario(
    IN p_id_usuario INTEGER,
    IN p_nombres VARCHAR,
    IN p_apellidos VARCHAR,
    IN p_telefono VARCHAR,
    IN p_direccion JSONB,
    IN p_correo_electronico VARCHAR
  ) LANGUAGE plpgsql AS $$ BEGIN
UPDATE usuarios
SET nombres = COALESCE(p_nombres, nombres),
  apellidos = COALESCE(p_apellidos, apellidos),
  telefono = COALESCE(p_telefono, telefono),
  direccion = COALESCE(p_direccion, direccion),
  correo_electronico = COALESCE(p_correo_electronico, correo_electronico),
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_usuario = p_id_usuario;
END;
$$;
--CAMBIAR_CONTRASENA(...) CAMBIA EL HASH DE LA CONTRASEÑA DEL USUARIO.
CREATE OR REPLACE PROCEDURE cambiar_contrasena(
    IN p_id_usuario INTEGER,
    IN p_nueva_contrasena_hash VARCHAR
  ) LANGUAGE plpgsql AS $$ BEGIN
UPDATE usuarios
SET contrasena_hash = p_nueva_contrasena_hash,
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_usuario = p_id_usuario;
END;
$$;
--AUTENTICAR_USUARIO(...)VERIFICA CREDENCIALES PARA INICIAR SESIÓN (VALIDACIÓN + ESTADO ACTIVO).
CREATE OR REPLACE PROCEDURE autenticar_usuario(
    IN p_correo_electronico VARCHAR,
    IN p_contrasena_hash VARCHAR,
    OUT p_id_usuario INTEGER,
    OUT p_nombre_usuario VARCHAR,
    OUT p_esta_activo BOOLEAN,
    OUT p_autenticado BOOLEAN
  ) LANGUAGE plpgsql AS $$ BEGIN
SELECT u.id_usuario,
  u.nombre_usuario,
  u.esta_activo,
  (
    u.contrasena_hash = p_contrasena_hash
    AND u.esta_activo
  ) INTO p_id_usuario,
  p_nombre_usuario,
  p_esta_activo,
  p_autenticado
FROM usuarios u
WHERE u.correo_electronico = p_correo_electronico
LIMIT 1;
END;
$$;
--GESTIONAR_ROL_USUARIO(...) CAMBIA EL ROL ASIGNADO A UN USUARIO.
CREATE OR REPLACE PROCEDURE gestionar_rol_usuario(
    IN p_id_usuario INTEGER,
    IN p_nuevo_id_rol INTEGER
  ) LANGUAGE plpgsql AS $$ BEGIN
UPDATE usuarios
SET id_rol = p_nuevo_id_rol,
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_usuario = p_id_usuario;
END;
$$ -- Procedimiento para actualizar precios
CREATE PROCEDURE actualizar_precio_producto(
  producto_id INTEGER,
  nuevo_precio DECIMAL(10, 2),
  usuario_id INTEGER,
  razon TEXT DEFAULT NULL
) LANGUAGE plpgsql AS $$
DECLARE precio_anterior DECIMAL(10, 2);
BEGIN -- Verificar si el producto existe
IF NOT EXISTS (
  SELECT 1
  FROM productos
  WHERE id_producto = producto_id
) THEN RAISE EXCEPTION 'El producto con ID % no existe',
producto_id;
END IF;
-- Verificar si el usuario existe
IF NOT EXISTS (
  SELECT 1
  FROM usuarios
  WHERE id_usuario = usuario_id
) THEN RAISE EXCEPTION 'El usuario con ID % no existe',
usuario_id;
END IF;
-- Obtener precio actual
SELECT precio INTO precio_anterior
FROM productos
WHERE id_producto = producto_id FOR
UPDATE;
-- Bloquea el registro para evitar condiciones de carrera
-- Validar el nuevo precio
IF nuevo_precio <= 0 THEN RAISE EXCEPTION 'El precio debe ser mayor que cero';
END IF;
-- Actualizar precio
UPDATE productos
SET precio = nuevo_precio,
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_producto = producto_id;
-- Insertar en historial de precios
INSERT INTO historial_precios (
    id_producto,
    precio_anterior,
    precio_nuevo,
    modificado_por,
    razon_cambio,
    fecha_cambio
  )
VALUES (
    producto_id,
    COALESCE(precio_anterior, 0),
    nuevo_precio,
    usuario_id,
    COALESCE(razon, 'Actualización de precio'),
    CURRENT_TIMESTAMP
  );
-- Confirmar la transacción
COMMIT;
EXCEPTION
WHEN OTHERS THEN -- Revertir la transacción en caso de error
ROLLBACK;
RAISE;
END;
$$;
-- Procedimiento para registrar movimientos de inventario
CREATE PROCEDURE registrar_movimiento_inventario(
  producto_id INTEGER,
  cambio_cantidad INTEGER,
  tipo_cambio VARCHAR(20),
  referencia_id INTEGER DEFAULT NULL,
  notas TEXT DEFAULT NULL,
  usuario_id INTEGER DEFAULT NULL
) LANGUAGE plpgsql AS $$
DECLARE cantidad_actual INTEGER;
nueva_cantidad INTEGER;
tipo_valido BOOLEAN;
BEGIN -- Validar tipo_cambio contra la restricción CHECK
SELECT tipo_cambio IN (
    'compra',
    'devolucion',
    'ajuste',
    'daño',
    'reabastecimiento'
  ) INTO tipo_valido;
IF NOT tipo_valido THEN RAISE EXCEPTION 'Tipo de cambio no válido. Debe ser uno de: compra, devolucion, ajuste, daño, reabastecimiento';
END IF;
-- Verificar si el producto existe
IF NOT EXISTS (
  SELECT 1
  FROM productos
  WHERE id_producto = producto_id
) THEN RAISE EXCEPTION 'El producto con ID % no existe',
producto_id;
END IF;
-- Verificar usuario si se proporciona
IF usuario_id IS NOT NULL
AND NOT EXISTS (
  SELECT 1
  FROM usuarios
  WHERE id_usuario = usuario_id
) THEN RAISE EXCEPTION 'El usuario con ID % no existe',
usuario_id;
END IF;
-- Obtener y bloquear el inventario actual
SELECT cantidad_disponible INTO cantidad_actual
FROM productos
WHERE id_producto = producto_id FOR
UPDATE;
-- Bloquea el registro para evitar condiciones de carrera
-- Calcular nuevo inventario
nueva_cantidad := cantidad_actual + cambio_cantidad;
-- Validar que el inventario no sea negativo
IF nueva_cantidad < 0 THEN RAISE EXCEPTION 'No hay suficiente inventario para el producto ID %. Disponible: %, Solicitado: %',
producto_id,
cantidad_actual,
ABS(cambio_cantidad);
END IF;
-- Actualizar producto
UPDATE productos
SET cantidad_disponible = nueva_cantidad,
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_producto = producto_id;
-- Registrar movimiento en inventario
INSERT INTO registro_inventario (
    id_producto,
    cambio_cantidad,
    nueva_cantidad,
    tipo_cambio,
    id_referencia,
    notas,
    modificado_por,
    fecha_cambio
  )
VALUES (
    producto_id,
    cambio_cantidad,
    nueva_cantidad,
    tipo_cambio,
    referencia_id,
    COALESCE(notas, 'Movimiento de inventario'),
    usuario_id,
    CURRENT_TIMESTAMP
  );
-- Confirmar la transacción
COMMIT;
EXCEPTION
WHEN OTHERS THEN -- Revertir la transacción en caso de error
ROLLBACK;
RAISE;
END;
$$;
-- Procedimiento para ajustar el inventario por pedido
CREATE PROCEDURE ajustar_inventario_por_pedido(
  pedido_id INTEGER,
  usuario_id INTEGER DEFAULT NULL
) LANGUAGE plpgsql AS $$
DECLARE item RECORD;
pedido_existe BOOLEAN;
usuario_valido BOOLEAN;
BEGIN -- Verificar si el pedido existe
SELECT EXISTS (
    SELECT 1
    FROM pedidos
    WHERE id_pedido = pedido_id
  ) INTO pedido_existe;
IF NOT pedido_existe THEN RAISE EXCEPTION 'El pedido con ID % no existe',
pedido_id;
END IF;
-- Verificar usuario si se proporciona
IF usuario_id IS NOT NULL THEN
SELECT EXISTS (
    SELECT 1
    FROM usuarios
    WHERE id_usuario = usuario_id
  ) INTO usuario_valido;
IF NOT usuario_valido THEN RAISE EXCEPTION 'El usuario con ID % no existe',
usuario_id;
END IF;
END IF;
-- Iniciar una transacción
BEGIN -- Recorrer todos los items del pedido
FOR item IN
SELECT ip.id_producto,
  ip.cantidad,
  p.nombre as nombre_producto
FROM items_pedido ip
  JOIN productos p ON ip.id_producto = p.id_producto
WHERE ip.id_pedido = pedido_id LOOP -- Usar el procedimiento registrar_movimiento_inventario para cada item
  -- Esto asegura que toda la lógica de validación se mantenga consistente
  CALL registrar_movimiento_inventario(
    producto_id := item.id_producto,
    cambio_cantidad := - item.cantidad,
    -- Restar del inventario
    tipo_cambio := 'compra',
    referencia_id := pedido_id,
    notas := 'Ajuste automático por pedido ' || pedido_id,
    usuario_id := usuario_id
  );
-- Registrar en el log
RAISE NOTICE 'Procesado producto % (ID: %), cantidad: %',
item.nombre_producto,
item.id_producto,
item.cantidad;
END LOOP;
-- Actualizar el estado del pedido a 'procesando' si está en 'pendiente'
UPDATE pedidos
SET estado = 'procesando',
  fecha_actualizacion = CURRENT_TIMESTAMP
WHERE id_pedido = pedido_id
  AND estado = 'pendiente';
-- Confirmar la transacción
COMMIT;
RAISE NOTICE 'Inventario actualizado correctamente para el pedido %',
pedido_id;
EXCEPTION
WHEN OTHERS THEN -- Revertir la transacción en caso de error
ROLLBACK;
RAISE EXCEPTION 'Error al procesar el pedido %: %',
pedido_id,
SQLERRM;
END;
END;
$$;