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
* Funcion: create_new_user
*
* Uso: crea un nuevo usuario en la base de datos, esto implica crear una cuenta, un perfil, relacionarlo con alguna institucion existente, e insertar en la bd una foto del usuario
*
* Parametros: nombre_u, apellido_u, fecha_nacimiento_u, telefono_u, email_u, password_hash, idioma_u, notificaciones_u, tema_u, sexo_u, latitud_u, longitud_u, foto_u, dominio_institucion, titulo_u, anio_ingreso, anio_egreso
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION create_new_user(nombre_u TEXT, apellido_u TEXT, fecha_nacimiento_u DATE, telefono_u TEXT, email_u TEXT, password_hash TEXT, idioma_u CHAR, notificaciones_u BOOLEAN, tema_u BOOLEAN, sexo_u TEXT, latitud_u DECIMAL(10, 8), longitud_u DECIMAL(11,8), foto_u TEXT, dominio_institucion TEXT, titulo_u TEXT, anio_ingreso INTEGER, anio_egreso INTEGER) 
RETURNS VOID 
LANGUAGE plpgsql
AS $$
DECLARE
    id_cuenta_u INTEGER;
BEGIN
    /* verificar que el correo o telefono no exista */
    IF EXISTS (SELECT * FROM cuenta WHERE email = email_u OR telefono = telefono_u) THEN
        RAISE EXCEPTION 'El correo o telefono ya esta registrado';
    END IF;

    /* verificar que la institucion exista */
    IF NOT EXISTS (SELECT * FROM institucion WHERE dominio = dominio_institucion) THEN
        RAISE EXCEPTION 'La institucion no existe';
    END IF;

    INSERT INTO cuenta (nombre, apellido, fecha_nacimiento, telefono, email, contrasena, idioma, notificaciones, tema) VALUES (nombre_u, apellido_u, fecha_nacimiento_u, telefono_u, email_u, password_hash, idioma_u, notificaciones_u, tema_u) RETURNING id_cuenta INTO id_cuenta_u;

    INSERT INTO perfil (id_cuenta, sexo, latitud, longitud) VALUES (id_cuenta_u, sexo_u, latitud_u, longitud_u);

    INSERT INTO estudio_en(id_cuenta, dominio, titulo, ano_ingreso, ano_egreso) VALUES (id_cuenta_u, dominio_institucion, titulo_u, anio_ingreso, anio_egreso);

    INSERT INTO tiene_foto (id_cuenta, foto) VALUES (id_cuenta_u, decode(foto_u, 'base64'));

END;
$$;
