DELIMITER //

CREATE PROCEDURE ObtenerFechasCategorias()
BEGIN
    SELECT 
        id AS categoria_id,
        name AS nombre_categoria,
        created_at AS fecha_creacion,
        updated_at AS fecha_actualizacion
    FROM 
        categories;
END //

DELIMITER ;


“products” Fecha de creación y actualización
DELIMITER //

CREATE PROCEDURE ObtenerFechasProductos()
BEGIN
    SELECT 
        id AS producto_id,
        name AS nombre_producto,
        created_at AS fecha_creacion,
        updated_at AS fecha_actualizacion
    FROM 
        products;
END //

DELIMITER ;

“sales” fecha de venta 
DELIMITER //

CREATE PROCEDURE ObtenerFechasVentas()
BEGIN
    SELECT 
        id AS venta_id,
        sale_date AS fecha_venta,
        created_at AS fecha_creacion,
        updated_at AS fecha_actualizacion
    FROM 
        sales;
END //

DELIMITER ;

product_movements – Fecha del movimiento

DELIMITER //

CREATE PROCEDURE ObtenerFechasMovimientosProductos()
BEGIN
    SELECT 
        id AS movimiento_id,
        movement_date AS fecha_movimiento,
        created_at AS fecha_creacion,
        updated_at AS fecha_actualizacion
    FROM 
        product_movements;
END //

DELIMITER ;

inventories – Fechas de inventario

DELIMITER //

CREATE PROCEDURE ObtenerFechasInventario()
BEGIN
    SELECT 
        id AS inventario_id,
        created_at AS fecha_creacion,
        updated_at AS fecha_actualizacion
    FROM 
        inventories;
END //

DELIMITER ;

purchases – Fechas de compra

DELIMITER //

CREATE PROCEDURE ObtenerFechasCompras()
BEGIN
    SELECT 
        id AS compra_id,
        purchase_date AS fecha_compra,
        created_at AS fecha_creacion,
        updated_at AS fecha_actualizacion
    FROM 
        purchases;
END //

DELIMITER ;

returns – Fechas de devoluciones
DELIMITER //

CREATE PROCEDURE ObtenerFechasDevoluciones()
BEGIN
    SELECT 
        id AS devolucion_id,
        return_date AS fecha_devolucion,
        created_at AS fecha_creacion,
        updated_at AS fecha_actualizacion
    FROM 
        returns;
END //

DELIMITER ;

Buscar una venta por fecha específica

DELIMITER //

CREATE PROCEDURE BuscarVentaPorFecha(
    IN fecha_param DATE
)
BEGIN
    SELECT 
        id AS venta_id,
        sale_date AS fecha_venta,
        total,
        created_at
    FROM 
        sales
    WHERE 
        sale_date = fecha_param;
END //

DELIMITER ;
