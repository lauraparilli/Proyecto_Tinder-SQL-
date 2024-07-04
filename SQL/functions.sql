/*
 * Funcion: set_coordenada()
 *
 * Uso: Cuando una fila se hace update o se inserta en una tabla que contenga las columnas de latitud y longitud se ejecuta automaticamente este trigger. Se setea la columna 'coordenada' creando un punto con los valores de 'longitud' y 'latitud'. El punto se asigna el SRID 4326.      
 *
 * Parametros: Ninguna

 * Retorna: La funcion trigger retorna la nueva fila con la coordenada seteada
 */
CREATE OR REPLACE FUNCTION set_coordenada()
RETURNS TRIGGER AS
$$
BEGIN
    New.coordenada = ST_SetSRID(ST_MakePoint(New.longitud, New.latitud), 4326);
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;


/*
 * funcion: set_latitud_longitud_origen()
 *
 * Uso: Cuando una fila se inserta o se hace update en la tabla 'preferencias' se ejecuta automaticamente este trigger. Se setea la columna 'coordenada_origen' creando un punto con los valores de 'longitud_origen' y 'latitud_origen'. El punto se asigna el SRID 4326. Si los valores de 'longitud_origen' y 'latitud_origen' son nulos (esto ocurre cuando se inserta una nueva fila), se setean con los valores de 'longitud' y 'latitud' de la tabla 'perfil' que tenga el mismo 'id_cuenta' que la fila insertada en 'preferencias'.
 *
 * Parametros: Ninguna
 *
 * Retorna: La funcion trigger retorna la nueva fila con la coordenada de origen insertada en la tabla 'preferencias'.
 */
CREATE OR REPLACE FUNCTION set_latitud_longitud_origen()
RETURNS TRIGGER AS
$$
BEGIN
    IF New.longitud_origen IS NULL OR New.latitud_origen IS NULL THEN
        SELECT p.latitud, p.longitud INTO NEW.latitud_origen, NEW.longitud_origen
        FROM perfil p
        WHERE p.id_cuenta = NEW.id_cuenta;
    END IF;
    New.coordenada_origen = ST_SetSRID(ST_MakePoint(New.longitud_origen, New.latitud_origen), 4326);
    RETURN NEW;
END;
$$

LANGUAGE plpgsql;



/*
 * Función: create_new_user

 * Uso: Crea un nuevo usuario en la base de datos con la información proporcionada.

 * Parámetros:
 *   - nombre_u: Texto que representa el nombre del usuario.
 *   - apellido_u: Texto que representa el apellido del usuario.
 *   - fecha_nacimiento_u: Fecha de nacimiento del usuario.
 *   - telefono_u: Texto que representa el número de teléfono del usuario.
 *   - email_u: Texto que representa el correo electrónico del usuario.
 *   - password_hash: Texto que representa el hash de la contraseña del usuario.
 *   - idioma_u: 3 caracteres que representa el idioma preferido del usuario.
 *   - notificaciones_u: Valor booleano que indica si el usuario desea recibir notificaciones.
 *   - tema_u: Valor booleano que indica el tema preferido del usuario.
 *   - sexo_u: Carácter que representa el sexo del usuario.
 *   - latitud_u: Valor decimal que representa la latitud de la ubicación del usuario.
 *   - longitud_u: Valor decimal que representa la longitud de la ubicación del usuario.
 *   - foto_u: Arreglo de textos en formato base64 que representa las fotos del usuario.
 *   - dominio_institucion: Texto que representa el dominio de la institución a la que estudio el usuario.
 *   - titulo_u: Texto que representa el título académico del usuario.
 *   - anio_ingreso: Valor entero que representa el año de ingreso a la institución.
 *   - anio_egreso: Valor entero que representa el año de egreso de la institución.
 *
 * Retorna: Nada.
 */
CREATE OR REPLACE FUNCTION create_new_user(nombre_u TEXT, apellido_u TEXT, fecha_nacimiento_u DATE, telefono_u TEXT, email_u TEXT, password_hash TEXT, idioma_u CHAR, notificaciones_u BOOLEAN, tema_u BOOLEAN, sexo_u TEXT, latitud_u DECIMAL(10, 8), longitud_u DECIMAL(11,8), foto_u TEXT[], dominio_institucion TEXT, titulo_u TEXT, anio_ingreso INTEGER, anio_egreso INTEGER) 
RETURNS VOID 
LANGUAGE plpgsql
AS $$
DECLARE
    id_cuenta_u INTEGER;
    i INTEGER;
BEGIN
    /* verificar que el correo o telefono no exista */
    IF EXISTS (SELECT * FROM cuenta WHERE email = email_u OR telefono = telefono_u) THEN
        RAISE EXCEPTION 'El correo o telefono ya esta registrado';
    END IF;

    /* verificar que la institucion exista */
    IF NOT EXISTS (SELECT * FROM institucion WHERE dominio = dominio_institucion) THEN
        RAISE EXCEPTION 'La institucion no existe';
    END IF;

    /*verificar que el año de egreso sea mayor o igual al de ingreso */
    IF anio_egreso <= anio_ingreso THEN
        RAISE EXCEPTION 'El año de egreso debe ser mayor o igual al de ingreso';
    END IF;

    INSERT INTO cuenta (nombre, apellido, fecha_nacimiento, telefono, email, contrasena, idioma, notificaciones, tema) VALUES (nombre_u, apellido_u, fecha_nacimiento_u, telefono_u, email_u, password_hash, idioma_u, notificaciones_u, tema_u) RETURNING id_cuenta INTO id_cuenta_u;

    INSERT INTO perfil (id_cuenta, sexo, latitud, longitud) VALUES (id_cuenta_u, sexo_u, latitud_u, longitud_u);

    INSERT INTO estudio_en(id_cuenta, dominio, titulo, ano_ingreso, ano_egreso) VALUES (id_cuenta_u, dominio_institucion, titulo_u, anio_ingreso, anio_egreso);

    FOR i IN 1..array_length(foto_u, 1) LOOP
        INSERT INTO tiene_foto (id_cuenta, foto) VALUES (id_cuenta_u, decode(foto_u[i], 'base64'));
    END LOOP;
END;
$$;

/**
 * Funcion: getAllInstitutions

 * Parametros: Ninguna

 * Uso: Retorna una tabla con los dominios y nombres de todas las instituciones registradas en la base de datos para que el usuario pueda seleccionar una de ellas al momento de registrarse

 * Retorna: Tabla con los dominios y nombres de todas las instituciones
 */
CREATE OR REPLACE FUNCTION getAllInstitutions()
RETURNS TABLE (dominio VARCHAR, nombre VARCHAR) 
AS $$
BEGIN
    RETURN QUERY SELECT i.dominio, i.nombre AS dominio_nombre FROM institucion i;
END;
$$ LANGUAGE plpgsql;
