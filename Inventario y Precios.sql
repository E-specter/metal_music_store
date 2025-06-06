--Prodecimiento para actualizar precios
CREATE PROCEDURE actualizar_precio_producto(
    producto_id INTEGER,
    nuevo_precio DECIMAL(10, 2),
    usuario_id INTEGER,
    razon TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    precio_anterior DECIMAL(10, 2);
BEGIN
    -- Obtener precio anterior
    SELECT precio INTO precio_anterior
    FROM productos
    WHERE id_producto = producto_id;

    -- Actualizar precio
    UPDATE productos
    SET precio = nuevo_precio,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id_producto = producto_id;

    -- Insertar en historial de precios
    INSERT INTO historial_precios (
        id_producto, precio_anterior, precio_nuevo, 
        modificado_por, razon_cambio, fecha_cambio
    )
    VALUES (
        producto_id, precio_anterior, nuevo_precio, 
        usuario_id, razon, CURRENT_TIMESTAMP
    );
END;
$$;

--Procedimiento para registrar movimientos
CREATE PROCEDURE registrar_movimiento_inventario(
    producto_id INTEGER,
    cambio_cantidad INTEGER,
    tipo_cambio VARCHAR(20),
    referencia_id INTEGER DEFAULT NULL,
    notas TEXT DEFAULT NULL,
    usuario_id INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    cantidad_actual INTEGER;
    nueva_cantidad INTEGER;
BEGIN
    -- Obtener inventario actual
    SELECT cantidad_disponible INTO cantidad_actual
    FROM productos
    WHERE id_producto = producto_id;

    -- Calcular nuevo inventario
    nueva_cantidad := cantidad_actual + cambio_cantidad;

    -- Actualizar producto
    UPDATE productos
    SET cantidad_disponible = nueva_cantidad,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id_producto = producto_id;

    -- Registrar movimiento en inventario
    INSERT INTO registro_inventario (
        id_producto, cambio_cantidad, nueva_cantidad, 
        tipo_cambio, id_referencia, notas, modificado_por, fecha_cambio
    )
    VALUES (
        producto_id, cambio_cantidad, nueva_cantidad, 
        tipo_cambio, referencia_id, notas, usuario_id, CURRENT_TIMESTAMP
    );
END;
$$;

--Procedimiento ajustar inventario
CREATE PROCEDURE ajustar_inventario_por_pedido(
    pedido_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    item RECORD;
    cantidad_actual INTEGER;
    nueva_cantidad INTEGER;
BEGIN
    FOR item IN
        SELECT id_producto, cantidad
        FROM items_pedido
        WHERE id_pedido = pedido_id
    LOOP
        SELECT cantidad_disponible INTO cantidad_actual
        FROM productos
        WHERE id_producto = item.id_producto;

        nueva_cantidad := cantidad_actual - item.cantidad;

        UPDATE productos
        SET cantidad_disponible = nueva_cantidad,
            fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE id_producto = item.id_producto;

        INSERT INTO registro_inventario (
            id_producto, cambio_cantidad, nueva_cantidad,
            tipo_cambio, id_referencia, notas, fecha_cambio
        )
        VALUES (
            item.id_producto, -item.cantidad, nueva_cantidad,
            'compra', pedido_id, 'Ajuste automático por pedido', CURRENT_TIMESTAMP
        );
    END LOOP;
END;
$$;

