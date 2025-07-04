-- Agregar a lista de deseos
CREATE PROCEDURE api_customer.  (
    _usuario_id INT,
    _producto_id INT,
    _nombre_lista VARCHAR(100) DEFAULT 'Principal'
) AS $$
DECLARE lista_id INT;
BEGIN
    -- Obtener o crear lista
    SELECT id_lista_deseos INTO lista_id
    FROM listas_deseos
    WHERE id_usuario = _usuario_id AND nombre = _nombre_lista;
    
    IF NOT FOUND THEN
        INSERT INTO listas_deseos(id_usuario, nombre)
        VALUES (_usuario_id, _nombre_lista)
        RETURNING id_lista_deseos INTO lista_id;
    END IF;
    
    -- Agregar producto
    INSERT INTO items_lista_deseos(id_lista_deseos, id_producto)
    VALUES (lista_id, _producto_id)
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Gestión de carrito (agregar/actualizar)
CREATE PROCEDURE api_customer.actualizar_carrito(
  _usuario_id INT,
  _producto_id INT,
  _cantidad INT
) AS $$ BEGIN IF _cantidad <= 0 THEN
DELETE FROM items_carrito
WHERE id_carrito = (
    SELECT id_carrito
    FROM carritos_compras
    WHERE id_usuario = _usuario_id
  )
  AND id_producto = _producto_id;
ELSE
INSERT INTO items_carrito (id_carrito, id_producto, cantidad)
VALUES (
    (
      SELECT id_carrito
      FROM carritos_compras
      WHERE id_usuario = _usuario_id
    ),
    _producto_id,
    _cantidad
  ) ON CONFLICT (id_carrito, id_producto) DO
UPDATE
SET cantidad = _cantidad;
END IF;
END;
$$ LANGUAGE plpgsql;

-- Checkout: Convertir carrito en pedido
CREATE FUNCTION api_customer.realizar_pedido(
  _usuario_id INT,
  _metodo_pago_id INT,
  _direccion_envio JSONB
) RETURNS VARCHAR AS $$
DECLARE _pedido_id INT;
_numero_pedido VARCHAR(50);
BEGIN -- Generar número de pedido único
_numero_pedido := 'PED-' || EXTRACT(
  YEAR
  FROM NOW()
) || '-' || LPAD(NEXTVAL('pedidos_num_seq')::TEXT, 6, '0');
INSERT INTO pedidos (
    id_usuario,
    numero_pedido,
    id_estado,
    subtotal,
    total,
    id_metodo_pago,
    estado_pago
  )
VALUES (
    _usuario_id,
    _numero_pedido,
    1,
    -- Estado 1 = Pendiente
    (
      SELECT SUM(p.precio * ic.cantidad)
      FROM items_carrito ic
        JOIN productos p ON ic.id_producto = p.id_producto
      WHERE id_carrito = (
          SELECT id_carrito
          FROM carritos_compras
          WHERE id_usuario = _usuario_id
        )
    ),

...-- Cálculos completos
  )
RETURNING id_pedido INTO _pedido_id;

-- Copiar items del carrito al pedido
INSERT INTO items_pedido (
    id_pedido,
    id_producto,
    cantidad,
    precio_unitario
  )
SELECT _pedido_id,
  ic.id_producto,
  ic.cantidad,
  p.precio
FROM items_carrito ic
  JOIN productos p ON ic.id_producto = p.id_producto
WHERE id_carrito = (
    SELECT id_carrito
    FROM carritos_compras
    WHERE id_usuario = _usuario_id
  );

-- Registrar dirección
INSERT INTO direcciones_pedido (id_pedido, tipo_direccion, datos_direccion)
VALUES (_pedido_id, 'envio', _direccion_envio);

-- Limpiar carrito
DELETE FROM items_carrito
WHERE id_carrito = (
    SELECT id_carrito
    FROM carritos_compras
    WHERE id_usuario = _usuario_id
  );
RETURN _numero_pedido;
END;
$$ LANGUAGE plpgsql;

-- Historial de pedidos con paginación
CREATE FUNCTION api_customer.historial_pedidos(
  _usuario_id INT,
  _pagina INT = 1,
  _por_pagina INT = 10
) RETURNS JSONB AS $$ BEGIN RETURN (
  SELECT jsonb_build_object(
      'total',
      COUNT(*),
      'pedidos',
      jsonb_agg(
        jsonb_build_object(
          'numero',
          p.numero_pedido,
          'fecha',
          p.fecha_creacion,
          'estado',
          ep.nombre_estado,
          'total',
          p.total
        )
      )
    )
  FROM pedidos p
    JOIN estados_pedido ep ON p.id_estado = ep.id_estado
  WHERE p.id_usuario = _usuario_id OFFSET (_pagina - 1) * _por_pagina
  LIMIT _por_pagina
);
END;
$$ LANGUAGE plpgsql;

-- Crear reseña
CREATE PROCEDURE api_customer.crear_resena(
    _usuario_id INT,
    _producto_id INT,
    _calificacion INT,
    _titulo VARCHAR(100),
    _comentario TEXT
) AS $$
BEGIN
    INSERT INTO reseñas_productos(id_producto, id_usuario, calificacion, titulo, comentario)
    VALUES (_producto_id, _usuario_id, _calificacion, _titulo, _comentario);
END;
$$ LANGUAGE plpgsql;

