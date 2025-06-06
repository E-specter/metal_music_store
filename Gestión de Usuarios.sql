--ACTUALIZAR_USUARIO(...) PERMITE ACTUALIZAR DATOS DEL USUARIO (EXCEPTO CONTRASEÑA).

CREATE OR REPLACE PROCEDURE actualizar_usuario(
    IN p_id_usuario INTEGER,
    IN p_nombres VARCHAR,
    IN p_apellidos VARCHAR,
    IN p_telefono VARCHAR,
    IN p_direccion JSONB,
    IN p_correo_electronico VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios
    SET
        nombres = COALESCE(p_nombres, nombres),
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
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios
    SET
        contrasena_hash = p_nueva_contrasena_hash,
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
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT 
        u.id_usuario,
        u.nombre_usuario,
        u.esta_activo,
        (u.contrasena_hash = p_contrasena_hash AND u.esta_activo)
    INTO 
        p_id_usuario,
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
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios
    SET 
        id_rol = p_nuevo_id_rol,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id_usuario = p_id_usuario;
END;
$$
