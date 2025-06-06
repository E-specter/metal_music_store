--PARA ACTUALIZAR UN PRODUCTO:
DELIMITER $$

CREATE PROCEDURE actualizar_producto (
  IN _id_producto INT,
  IN _nombre VARCHAR(255),
  IN _descripcion TEXT,
  IN _precio DECIMAL(10,2),
  IN _costo DECIMAL(10,2),
  IN _cantidad_disponible INT,
  IN _id_categoria INT,
  IN _marca VARCHAR(100),
  IN _talla VARCHAR(50),
  IN _material VARCHAR(100),
  IN _peso DECIMAL(10,2),
  IN _atributos JSON
)
BEGIN
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
END $$

DELIMITER ;


--PARA DESACTIVAR UN PRODUCTO:

DELIMITER $$

CREATE PROCEDURE desactivar_producto(IN _id_producto INT)
BEGIN
  UPDATE productos
  SET esta_activo = FALSE,
      fecha_actualizacion = CURRENT_TIMESTAMP
  WHERE id_producto = _id_producto;
END $$

DELIMITER ;
PARA AÑADIR CATEGORIA:
DELIMITER $$

CREATE PROCEDURE agregar_categoria(
  IN _nombre VARCHAR(100),
  IN _descripcion TEXT,
  IN _id_categoria_padre INT,
  IN _slug VARCHAR(100)
)
BEGIN
  INSERT INTO categorias (nombre, descripcion, id_categoria_padre, slug)
  VALUES (_nombre, _descripcion, _id_categoria_padre, _slug);
END $$

DELIMITER ;


--PARA ACTUALIZAR CATEGORIA:

DELIMITER $$

CREATE PROCEDURE actualizar_categoria(
  IN _id_categoria INT,
  IN _nombre VARCHAR(100),
  IN _descripcion TEXT,
  IN _id_categoria_padre INT,
  IN _slug VARCHAR(100)
)
BEGIN
  UPDATE categorias
  SET nombre = _nombre,
      descripcion = _descripcion,
      id_categoria_padre = _id_categoria_padre,
      slug = _slug,
      fecha_actualizacion = CURRENT_TIMESTAMP
  WHERE id_categoria = _id_categoria;
END $$

DELIMITER ;
