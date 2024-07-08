/*
* Función: prevent_delete_any_row
*
* Uso: Prohibir eliminar una fila de una tabla (ejemplo una institucion).
*
* Parámetros: Ninguna.
*
* Resultado: Función trigger que evita que se elimine una fila de una tabla.
*/
CREATE OR REPLACE FUNCTION prevent_delete_any_row()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Prohibido eliminar una fila de esta tabla';
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


/*
* Función: set_coordenada()
*
* Uso: Cuando una fila se hace update o se inserta en una tabla que contenga las columnas de latitud y longitud se ejecuta automaticamente este trigger. Se setea la columna 'coordenada' creando un punto con los valores de 'longitud' y 'latitud'. El punto se asigna el SRID 4326.
*
* Parámetros: Ninguna.
*
* Retorna: La función trigger retorna la nueva fila con la coordenada seteada.
*/
CREATE OR REPLACE FUNCTION set_coordenada()
RETURNS TRIGGER AS $$
BEGIN
    New.coordenada = ST_SetSRID(ST_MakePoint(New.longitud, New.latitud), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
* Función: set_latitud_longitud_origen()
*
* Uso: Cuando una fila se inserta o se hace update en la tabla 'preferencias' se ejecuta automaticamente este trigger. Se setea la columna 'coordenada_origen' creando un punto con los valores de 'longitud_origen' y 'latitud_origen'. El punto se asigna el SRID 4326. Si los valores de 'longitud_origen' y 'latitud_origen' son nulos (esto ocurre cuando se inserta una nueva fila), se setean con los valores de 'longitud' y 'latitud' de la tabla 'perfil' que tenga el mismo 'id_cuenta' que la fila insertada en 'preferencias'.
*
* Parámetros: Ninguna.
*
* Retorna: La función trigger retorna la nueva fila con la coordenada de origen insertada en la tabla 'preferencias'.
*/
CREATE OR REPLACE FUNCTION set_latitud_longitud_origen()
RETURNS TRIGGER AS $$
BEGIN
    IF New.longitud_origen IS NULL OR New.latitud_origen IS NULL THEN
        SELECT p.latitud, p.longitud INTO NEW.latitud_origen, NEW.longitud_origen
        FROM   perfil p
        WHERE  p.id_cuenta = NEW.id_cuenta;
    END IF;
    New.coordenada_origen = ST_SetSRID(ST_MakePoint(New.longitud_origen, New.latitud_origen), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_institution
* 
* Uso: Insertar una institucion a la base de datos.
*
* Parámetros:
*  - i_dominio       : Dominio de la institucion.
*  - i_nombre        : Nombre de la institucion.
*  - i_tipo          : Tipo de la institucion.
*  - i_ano_fundacion : Año de fundacion de la institucion.
*  - i_latitud       : Latitud de la institucion.
*  - i_longitud      : Longitud de la institucion.
*
* Retorno: Nada.
*/
CREATE OR REPLACE FUNCTION insert_institution(i_dominio TEXT, i_nombre TEXT, i_tipo TEXT, i_ano_fundacion INTEGER, i_latitud DECIMAL, i_longitud DECIMAL) 
RETURNS VOID AS $$
BEGIN
    INSERT INTO institucion VALUES (i_dominio, i_nombre, i_tipo, i_ano_fundacion, i_latitud, i_longitud);
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_all_Institutions
*
* Parámetros: Ninguna.
*
* Uso: Retorna una tabla con los dominios y nombres de todas las instituciones registradas en la base de datos para que el usuario pueda seleccionar una de ellas al momento de registrarse.
*
* Retorna: Tabla con los dominios y nombres de todas las instituciones.
*/
CREATE OR REPLACE FUNCTION get_all_Institutions()
RETURNS TABLE (dominio VARCHAR, nombre VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT dominio, nombre FROM institucion;
END;
$$ LANGUAGE plpgsql;


/*
* Función: create_new_user
*
* Uso: Crea un nuevo usuario en la base de datos con la información proporcionada.
*
* Parámetros:
*   - nombre_u            : Nombre del usuario.
*   - apellido_u          : Apellido del usuario.
*   - fecha_nacimiento_u  : Fecha de nacimiento del usuario.
*   - telefono_u          : Número de teléfono del usuario.
*   - email_u             : Correo electrónico del usuario.
*   - password_hash       : Hash de la contraseña del usuario.
*   - idioma_u            : Idioma preferido del usuario.
*   - notificaciones_u    : Valor booleano que indica si el usuario desea recibir notificaciones.
*   - tema_u              : Valor booleano que indica el tema preferido del usuario.
*   - sexo_u              : Sexo del usuario.
*   - latitud_u           : Valor decimal que representa la latitud de la ubicación del usuario.
*   - longitud_u          : Valor decimal que representa la longitud de la ubicación del usuario.
*   - foto_u              : Arreglo de textos en formato base64 que representa las fotos del usuario.
*   - dominio_institucion : Dominio de la institución a la que estudio el usuario.
*   - grado_u             : Grado académico en el titulo del usuario.
*   - especialidad_u      : Especialidad en el titulo del usuario.
*   - anio_ingreso        : Valor entero que representa el año de ingreso a la institución.
*   - anio_egreso         : Valor entero que representa el año de egreso de la institución.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION create_new_user(nombre_u TEXT, apellido_u TEXT, fecha_nacimiento_u DATE, telefono_u TEXT, email_u TEXT, password_hash TEXT, idioma_u TEXT, notificaciones_u BOOLEAN, tema_u BOOLEAN, sexo_u TEXT, latitud_u DECIMAL(10, 8), longitud_u DECIMAL(11,8), foto_u TEXT[], dominio_institucion TEXT, grado_u TEXT, especialidad_u TEXT, anio_ingreso INTEGER, anio_egreso INTEGER) 
RETURNS VOID AS $$
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

    INSERT INTO estudio_en(id_cuenta, dominio, grado, especialidad, ano_ingreso, ano_egreso) VALUES (id_cuenta_u, dominio_institucion, grado_u, especialidad_u, anio_ingreso, anio_egreso);

    FOR i IN 1..array_length(foto_u, 1) LOOP
        INSERT INTO tiene_foto (id_cuenta, foto) VALUES (id_cuenta_u, decode(foto_u[i], 'base64'));
    END LOOP;
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_email_and_hashpassword_user
*
* Uso: Obtener el correo y el hash de la contrasena del usuario (para logins y cambios de contrasenas).
*
* Parámetros:
*   - id_user: Valor entero del id del usuario.
*
* Retorna: El email y el hash de la contrasena del usuario.
*/
CREATE OR REPLACE FUNCTION get_email_and_hashpassword_user(id_user integer)
RETURNS TABLE(r_email CHARACTER VARYING, r_contrasena CHARACTER VARYING) AS $$
BEGIN
    RETURN QUERY
    SELECT email, contrasena
    FROM   cuenta
    WHERE  id_cuenta = id_user;
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_settings_app_user
*
* Uso: Obtener el idioma, notificaciones y tema del app que tiene un usuario.
*
* Parámetros:
*   - id_user: Entero del id de la cuenta.
*
* Retorna: Una tabla con el idioma, notificaciones y tema del app que tiene un usuario.
*/
CREATE OR REPLACE FUNCTION get_settings_app_user(id_user INTEGER)
RETURNS TABLE (r_idioma idiomas_app, r_notificaciones BOOLEAN, r_tema BOOLEAN) AS $$
BEGIN
    RETURN QUERY
    SELECT idioma, notificaciones, tema
    FROM   cuenta
    WHERE  id_cuenta = id_user;
END;
$$ LANGUAGE plpgsql;


/*
* Función: update_info_account
*
* Uso: Actualiza la informacion de la cuenta de un usuario en la tabla de cuenta. Recordar que el usuario no puede cambiar su nombre ni apellido.
*
* Parámetros:
*  - c_id_cuenta      : Valor entero del ID de la cuenta del usuario.
*  - c_email          : (OPCIONAL) Texto con el nuevo email del usuario.
*  - c_contrasena     : (OPCIONAL) Texto con el nuevo hash de contrasena del usuario.
*  - c_telefono       : (OPCIONAL) Texto con el nuevo telefono del usuario.
*  - c_idioma         : (OPCIONAL) Texto con el nuevo idioma del usuario.
*  - c_tema           : (OPCIONAL) Texto con el nuevo tema del usuario.
*  - c_notificaciones : (OPCIONAL) Valor booleano con el nuevo valor de notificaciones del usuario.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_info_account(
    c_id_cuenta      INTEGER,
    c_email          TEXT DEFAULT NULL,
    c_contrasena     TEXT DEFAULT NULL,
    c_telefono       TEXT DEFAULT NULL,
    c_idioma         TEXT DEFAULT NULL,
    c_tema           BOOLEAN DEFAULT NULL,
    c_notificaciones BOOLEAN DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE cuenta
    SET email          = CASE WHEN c_email          IS NOT NULL THEN c_email          ELSE email          END,
        contrasena     = CASE WHEN c_contrasena     IS NOT NULL THEN c_contrasena     ELSE contrasena     END,
        telefono       = CASE WHEN c_telefono       IS NOT NULL THEN c_telefono       ELSE telefono       END,
        idioma         = CASE WHEN c_idioma         IS NOT NULL THEN c_idioma         ELSE idioma         END,
        tema           = CASE WHEN c_tema           IS NOT NULL THEN c_tema           ELSE tema           END,
        notificaciones = CASE WHEN c_notificaciones IS NOT NULL THEN c_notificaciones ELSE notificaciones END
    WHERE id_cuenta = c_id_cuenta;
END;
$$ LANGUAGE plpgsql;


/*
* Función: update_location_account
*
* Uso: Actualiza la ubicacion del usuario.
*
* Parámetros:
*   - p_id_cuenta : Valor entero que representa el id de la cuenta.
*   - p_latitud   : DECIMAL que representa la nueva latitud del usuario.
*   - p_longitud  : DECIMAL que representa la nueva longitud del usuario.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_location_account(p_id_cuenta INTEGER, p_latitud DECIMAL, p_longitud DECIMAL) 
RETURNS VOID AS $$
BEGIN
    UPDATE perfil 
    SET    latitud   = p_latitud, 
           longitud  = p_longitud 
    WHERE  id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;


/*
* Función: update_description_on_perfil
* 
* Uso: Actualiza la descripcion del perfil de un usuario.
*
* Parámetros: 
*  - id_user       : Valor entero del nombre del usuario a editar la descripcion del perfil.
*  - new_descripcion : Texto con la nueva descripcion del perfil.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_description_on_perfil(id_user INTEGER, new_descripcion TEXT)
RETURNS VOID
AS $$
BEGIN
    UPDATE perfil SET descripcion = new_descripcion WHERE id_cuenta = id_user;
END;
$$ LANGUAGE plpgsql;


/*
* Función: update_sexo_perfil
*
* Uso: Actualiza el sexo de un perfil de una cuenta.
*
* Parámetros:
*   - p_id_cuenta : Valor entero que representa el id de la cuenta.
*   - p_sexo      : Texto que representa el sexo del perfil a modificar.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_sexo_perfil(p_id_cuenta integer, p_sexo text)
RETURNS void AS
$$
BEGIN
    UPDATE perfil
    SET    sexo      = p_sexo
    WHERE  id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;



/*
* Función: set_true_verificado
*
* Uso: Setea true cuando el usuario completo exitosamente el proceso de verificar perfil.
*
* Parámetros:
*   - p_id_cuenta: Valor entero que representa el id de la cuenta.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION set_true_verificado(p_id_cuenta integer)
RETURNS VOID AS $$
BEGIN
    UPDATE perfil
    SET    verificado = TRUE
    WHERE  id_cuenta  = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_preferences
*
* Uso: Insertar las preferencias de un usuario en la tabla de preferencias.
*
* Parámetros:
*  - p_id_cuenta        : Valor entero del ID de la cuenta del usuario.
*  - p_estudio          : (Opcional) TEXT del nivel de estudio del usuario.
*  - p_latitud_origen   : (Opcional) DECIMAL de la latitud de preferencia del usuario.
*  - p_longitud_origen  : (Opcional) DECIMAL de la longitud de preferencia del usuario.
*  - p_distancia_maxima : (Opcional) Valor entero de la distancia máxima de búsqueda del usuario.
*  - p_min_edad         : (Opcional) Valor entero de la edad mínima de búsqueda del usuario.
*  - p_max_edad         : (Opcional) Valor entero de la edad máxima de búsqueda del usuario.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_preferences(
    p_id_cuenta        INTEGER,
    p_estudio          TEXT DEFAULT NULL,
    p_latitud_origen   DECIMAL(10, 8) DEFAULT NULL,
    p_longitud_origen  DECIMAL(11, 8) DEFAULT NULL,
    p_distancia_maxima INTEGER DEFAULT 5,
    p_min_edad         INTEGER DEFAULT 30,
    p_max_edad         INTEGER DEFAULT 99
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO preferencias(id_cuenta, estudio, latitud_origen, longitud_origen, distancia_maxima, min_edad, max_edad)
    VALUES (p_id_cuenta, p_estudio, p_latitud_origen, p_longitud_origen, p_distancia_maxima, p_min_edad, p_max_edad);
END;
$$ LANGUAGE plpgsql;


/*
* Función: update_preferences
*
* Uso: Actualiza las preferencias de un usuario en la tabla de preferencias.
*
* Parámetros:
*    - p_id_cuenta        : Valor entero del ID de la cuenta del usuario.
*    - p_estudio          : (Opcional) TEXT del nivel de estudio del usuario.
*    - p_latitud_origen   : (Opcional) DECIMAL de la latitud de preferencia del usuario.
*    - p_longitud_origen  : (Opcional) DECIMAL de la longitud de preferencia del usuario.
*    - p_distancia_maxima : (Opcional) Valor entero de la distancia máxima de búsqueda del usuario.
*    - p_min_edad         : (Opcional) Valor entero de la edad mínima de búsqueda del usuario.
*    - p_max_edad         : (Opcional) Valor entero de la edad máxima de búsqueda del usuario.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_preferences(
    p_id_cuenta        INTEGER,
    p_estudio          TEXT DEFAULT NULL,
    p_latitud_origen   DECIMAL(10, 8) DEFAULT NULL,
    p_longitud_origen  DECIMAL(11, 8) DEFAULT NULL,
    p_distancia_maxima INTEGER DEFAULT NULL,
    p_min_edad         INTEGER DEFAULT NULL,
    p_max_edad         INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE preferencias
    SET estudio          = CASE WHEN p_estudio          IS NOT NULL THEN p_estudio          ELSE estudio          END, 
        latitud_origen   = CASE WHEN p_latitud_origen   IS NOT NULL THEN p_latitud_origen   ELSE latitud_origen   END,
        longitud_origen  = CASE WHEN p_longitud_origen  IS NOT NULL THEN p_longitud_origen  ELSE longitud_origen  END,
        distancia_maxima = CASE WHEN p_distancia_maxima IS NOT NULL THEN p_distancia_maxima ELSE distancia_maxima END,
        min_edad         = CASE WHEN p_min_edad         IS NOT NULL THEN p_min_edad         ELSE min_edad         END,
        max_edad         = CASE WHEN p_max_edad         IS NOT NULL THEN p_max_edad         ELSE max_edad         END
    WHERE id_cuenta = p_id_cuenta;
END;
$$
 LANGUAGE plpgsql;
-- Ejemplo de uso SELECT update_preferences(p_id_cuenta := 19, p_estudio := 'Doctorado', p_distancia_maxima := 50);


/*
* Función: get_preferencias()
*
* Uso: Obtener las preferencias de un usuario.
*
* Parámetros: 
*    - p_id_cuenta : Valor entero del ID de la cuenta del usuario.
*
* Retorna : Todos los datos de preferencias de un usuario.
*/
CREATE OR REPLACE FUNCTION get_preferencias(p_id_cuenta integer)
RETURNS TABLE(
    r_estudio                     estudios,
    r_latitud_origen              NUMERIC,
    r_longitud_origen             NUMERIC,
    r_distancia_max               INTEGER,
    r_min_edad                    INTEGER,
    r_max_edad                    INTEGER,
    r_pref_orientaciones_sexuales orientaciones[],
    r_pref_sexos                  sexos[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.estudio,
        p.latitud_origen,
        p.longitud_origen,
        p.distancia_maxima,
        p.min_edad,
        p.max_edad,
        ARRAY(
            SELECT pref.orientacion_sexual 
            FROM pref_orientacion_sexual AS pref 
            WHERE pref.id_cuenta = p.id_cuenta
        ),
        ARRAY(
            SELECT pref.sexo 
            FROM pref_sexo AS pref 
            WHERE pref.id_cuenta = p.id_cuenta
        )
    FROM  preferencias AS p
    WHERE p.id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_users_by_estudio
*
* Uso: Obtener usuarios por preferencias en estudio.
*
* Parámetros:
*   - estudio : TEXT de estudio.
*
* Retorna: Una tabla con los usuarios que cumplen con el estudio especificado.
*/

CREATE OR REPLACE FUNCTION get_users_by_estudio(p_estudio TEXT)
RETURNS TABLE (r_id_cuenta INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT id_cuenta
    FROM   estudio_en
    WHERE  grado = p_estudio;
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_users_by_genre
*
* Uso: Obtener usuarios por preferencias en generos.
*
* Parámetros:
*   - genre : Arreglo de TEXT de generos.
*
* Retorna: Una tabla con los usuarios que cumplen con alguno de los generos especificados.
*/

CREATE OR REPLACE FUNCTION get_users_by_genre(genre TEXT[])
RETURNS TABLE (r_id_cuenta INTEGER)
AS $$
BEGIN
    /* Si el usuario no seteo el genero de preferencia */
    IF genre IS NULL THEN
        RETURN QUERY
        SELECT id_cuenta
        FROM   cuenta;
    END IF;

    RETURN QUERY
    SELECT id_cuenta
    FROM   perfil
    WHERE  sexo = ANY(genre);
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_users_by_min_age
*
* Uso: Obtener usuarios por preferencias en min edad
*
* Parámetros: 
*   - min_age: Entero de la edad minima
*
* Retorna: Una tabla con los usuarios que cumplen con el min edad.
*/
CREATE OR REPLACE FUNCTION get_users_by_min_age(min_age INTEGER)
RETURNS TABLE (r_id_cuenta INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT id_cuenta
    FROM   cuenta
    WHERE (EXTRACT(YEAR FROM AGE(fecha_nacimiento)) >= min_age);
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_users_by_max_age
*
* Uso: Obtener usuarios por preferencias en max edad.
*
* Parámetros:
*   - max_age: Entero de la edad maxima.
*
* Retorna: Una tabla con los usuarios que cumplen con el max edad.
*/
CREATE OR REPLACE FUNCTION get_users_by_max_age(max_age INTEGER)
RETURNS TABLE (r_id_cuenta INTEGER)
AS $$
BEGIN
    RETURN QUERY
    SELECT id_cuenta
    FROM cuenta
    WHERE (EXTRACT(YEAR FROM AGE(fecha_nacimiento)) <= max_age);
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_users_by_orientation_sexual
*
* Uso: Obtener los usuarios por preferencias de un arreglo de TEXT de orientaciones sexuales.
*
* Parámetros:
*   - orientation_sexual : Arreglo de TEXT con las orientaciones sexuales.
*
* Retorna: Tabla con los IDs de usuarios que tienen alguna de las orientaciones sexuales especificadas.
*/
CREATE OR REPLACE FUNCTION get_users_by_orientation_sexual(orientation_sexual TEXT[])
RETURNS TABLE(r_id_cuenta INTEGER) AS $$
BEGIN
    /* Si el usuario no seteo la orientacion sexual de preferencia */
    IF orientation_sexual IS NULL THEN
        RETURN QUERY
        SELECT id_cuenta
        FROM   cuenta;
    END IF;

    RETURN QUERY
    SELECT id_cuenta
    FROM   tiene_orientacion_sexual
    WHERE  orientacion_sexual = ANY(orientation_sexual);
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_all_users_by_max_distance
*
* Uso: Obtener todos los IDs de los usuarios que se encuentren a una distancia máxima de un usuario dado (no se considera en el resultado el usuario dado).
*
* Parámetros:
*  - user_id : Valor entero del Id de la cuenta del usuario a partir del cual se calculará la distancia..
*
* Retorno: Una tabla con los IDs de los usuarios que se encuentren a una distancia máxima de un usuario dado.
*/
CREATE OR REPLACE FUNCTION get_all_users_by_max_distance(user_id INTEGER)
RETURNS TABLE (id_cuenta_at_max_distance INTEGER) AS $$
DECLARE 
    max_distance INTEGER := 5;  -- DEFAULT VALUE 5 km
BEGIN
    /* Verificar si existe una instancia de preferencias del usuario */
    IF EXISTS (SELECT * FROM preferencias WHERE id_cuenta = user_id) THEN
        SELECT distancia_maxima FROM preferencias WHERE id_cuenta = user_id INTO max_distance;
    END IF;

    RETURN QUERY SELECT id_cuenta
    FROM perfil
    WHERE ST_DistanceSphere(
        coordenada,
        (SELECT coordenada FROM perfil WHERE id_cuenta = user_id)
    ) / 1000 <= max_distance AND id_cuenta != user_id;
END;
$$ LANGUAGE plpgsql;

/*
* Función: get_users_by_preferences_free_user
*
* Uso: Obtener los ids cuentas de los usuarios que cumplen con las preferencias de otro usuario que no tiene suscripcion con passport.
*
* Parámetros:
*  - user_id : id del usuario que tiene las preferencias.
*
* Retorna: Tabla con los ids de las cuentas de los usuarios que cumplen con las preferencias.
*/
CREATE OR REPLACE FUNCTION get_users_by_preferences_free_user(user_id integer)
RETURNS TABLE(pref_id_cuentas integer) AS $$
DECLARE
    pref_estudio     TEXT;
    pref_min_age     INTEGER;
    pref_max_age     INTEGER;
    pref_genre       TEXT[];
    pref_orientation TEXT[];
BEGIN
    SELECT min_edad, max_edad, estudio
    INTO   pref_min_age, pref_max_age, pref_estudio
    FROM   preferencias
    WHERE  id_cuenta = user_id;

    SELECT array_agg(sexo)
    INTO   pref_genre
    FROM   pref_sexo
    WHERE  id_cuenta = user_id;

    SELECT array_agg(orientacion_sexual)
    INTO   pref_orientation
    FROM   pref_orientacion_sexual
    WHERE  id_cuenta = user_id;

    RETURN QUERY
    SELECT id_cuenta
    FROM   cuenta
    WHERE  id_cuenta != user_id
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_estudio(pref_estudio))
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_min_age(pref_min_age))
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_max_age(pref_max_age))
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_genre(pref_genre))
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_orientation_sexual(pref_orientation))
        AND id_cuenta IN (SELECT id_cuenta_at_max_distance FROM get_all_users_by_max_distance(user_id));
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_pref_sexo
*
* Uso: Inserta una nueva preferencia de sexo para un usuario en la tabla de pref_sexo.
* 
* Parámetros: 
*  - p_id_cuenta : Valor entero del ID de la cuenta del usuario.
*  - p_sexo      : Texto que indica el nuevo sexo de preferencia del usuario.
* 
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_pref_sexo(p_id_cuenta INTEGER, p_sexo TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO pref_sexo(id_cuenta, sexo) VALUES (p_id_cuenta, p_sexo);
END;
$$ LANGUAGE plpgsql;


/*
* Función: delete_pref_sexo
*
* Uso: Elimina una preferencia de sexo de un usuario en la tabla de pref_sexo.
*
* Parámetros:
*  - p_id_cuenta : Valor entero del ID de la cuenta del usuario.
*  - p_sexo      : Texto que indica el sexo a eliminar de las preferencias del usuario.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_pref_sexo(p_id_cuenta INTEGER, p_sexo TEXT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM pref_sexo WHERE id_cuenta = p_id_cuenta AND sexo = p_sexo;
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_pref_orientacion_sexual
*
* Uso: Inserta una nueva preferencia de orientacion sexual para un usuario en la tabla de pref_orientacion_sexual.
*
* Parámetros:
*  - p_id_cuenta: Valor entero del ID de la cuenta del usuario.
*  - p_orientacion_sexual: Texto que indica la nueva orientacion sexual de preferencia del usuario.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_pref_orientacion_sexual(p_id_cuenta INTEGER, p_orientacion_sexual TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO pref_orientacion_sexual(id_cuenta, orientacion_sexual) VALUES (p_id_cuenta, p_orientacion_sexual);
END;
$$ LANGUAGE plpgsql;


/*
* Función: delete_pref_orientacion_sexual
*
* Uso: Elimina una preferencia de orientacion sexual de un usuario en la tabla de pref_orientacion_sexual.
*
* Parámetros:
*  - p_id_cuenta          : Valor entero del ID de la cuenta del usuario.
*  - p_orientacion_sexual : Texto que indica la orientacion sexual a eliminar de las preferencias del usuario.
*
* Retorno: Nada.
*/
CREATE OR REPLACE FUNCTION delete_pref_orientacion_sexual(p_id_cuenta INTEGER, p_orientacion_sexual TEXT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM pref_orientacion_sexual WHERE id_cuenta = p_id_cuenta AND orientacion_sexual = p_orientacion_sexual;
END;
$$ LANGUAGE plpgsql;

/*
* Función: insert_user_tarjeta
*
* Uso: Cuando el usuario registra una tarjeta, se inserta una instancia en la tabla tarjeta (si es que aun no existen en la base de datos), y se asocia a la cuenta del usuario creando una instancia en la tabla registra.
* 
* Parámetros:
* 	- user_id     : Valor entero que indica el id del usuario.
* 	- card_number : TEXT numero de la tarjeta.
*   - titular     : TEXT nombre del titular de la tarjeta.
*   - due_date    : DATE fecha de vencimiento de la tarjeta.
*   - cvv         : TEXT codigo de seguridad de la tarjeta.
*   - type_card   : TEXT tipo de tarjeta.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_user_tarjeta(user_id INT, card_number TEXT, titular TEXT, due_date DATE, cvv TEXT, type_card TEXT) 
RETURNS VOID AS $$
BEGIN
    /* Chequear que no este vencida la tarjeta */
    IF due_date < current_date THEN
        RAISE EXCEPTION 'La tarjeta esta vencida';
    END IF;

    IF NOT EXISTS (SELECT * FROM tarjeta WHERE digitos_tarjeta = card_number) THEN
        INSERT INTO tarjeta VALUES (card_number, titular, due_date, cvv, type_card);
    END IF;
    INSERT INTO registra VALUES (user_id, card_number);
END;
$$ LANGUAGE plpgsql;


/*
* Función: delete_instance_registra
*
* Uso: Elimina una instancia de la tabla registra.
* 
* Parámetros:
* 	- user_id     : Valor entero que indica el id del usuario.
* 	- card_number : TEXT numero de la tarjeta.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_instance_registra(user_id INTEGER, card_number TEXT) 
RETURNS VOID AS $$
BEGIN
    DELETE FROM registra WHERE id_cuenta = user_id AND digitos_tarjeta = card_number;
END;
$$ LANGUAGE plpgsql;


/*
* Función: update_due_date_card
*
* Uso: Actualizar la fecha de vencimiento de una tarjeta.
*
* Parámetros: 
*     - card_number  : TEXT indica los numeros de la tarjeta a modificar fecha de caducidad.
*     - new_due_date : DATE indica la nueva fecha de vencimiento de la tarjeta.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_due_date_card(card_number TEXT, new_due_date DATE)
RETURNS VOID AS $$
BEGIN
    UPDATE tarjeta
    SET    fecha_caducidad = new_due_date
    WHERE  digitos_tarjeta = card_number;
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_all_public_info_about_user
*
* Uso: Obtener todos los datos que sean considerados como publico de un usuario con su id_cuenta (nombre, apellido, edad, sexo, descripcion, verificado, latitud y longitud para mostrar la ciudad y pais con Nominatim, dominios de las instituciones en que estudio, Ids de la empresa que trabaja, hobbies, habilidades, certificaciones, fotos, orientaciones sexuales) para mostrarse en el perfil.
*
* Parámetros:
*   - id_user : id de la cuenta del usuario.
*
* Retorno: Devuelve una tabla de una fila con todos los datos (mencionados en el Uso) del usuario con el id_cuenta.
*/
CREATE OR REPLACE FUNCTION get_all_public_info_about_user(id_user integer)
RETURNS TABLE (
    r_nombre             CHARACTER VARYING,
    r_apellido           CHARACTER VARYING,
    r_edad               INTEGER,
    r_sexo               sexos,
    r_descripcion        CHARACTER VARYING,
    r_verificado         BOOLEAN,
    r_latitud            DECIMAL,
    r_longitud           DECIMAL,
    r_instituciones      CHARACTER VARYING[],
    r_empresas           INTEGER[],
    r_hobbies            hobbies[],
    r_certificaciones    CHARACTER VARYING[],
    r_habilidades        habilidades[],
    r_fotos              TEXT[],
    r_orientacion_sexual orientaciones[]
) AS $$
DECLARE
    edad INTEGER;
BEGIN
    RETURN QUERY
    SELECT
        nombre, apellido, EXTRACT(YEAR FROM AGE(fecha_nacimiento))::INTEGER as edad,
        sexo, descripcion, verificado, latitud, longitud,
        ARRAY(
            SELECT e.dominio
            FROM   estudio_en AS e
            WHERE  e.id_cuenta = id_user
        ),
        ARRAY(
            SELECT t.id_empresa
            FROM   trabaja_en AS t
            WHERE  t.id_cuenta = id_user
        ),
        ARRAY(
            SELECT h.hobby
            FROM   tiene_hobby AS h
            WHERE  h.id_cuenta = id_user
        ),
        ARRAY(
            SELECT c.certificaciones
            FROM   tiene_certificaciones AS c
            WHERE  c.id_cuenta = id_user
        ),
        ARRAY(
            SELECT h.habilidad
            FROM   tiene_habilidades AS h
            WHERE  h.id_cuenta = id_user
        ),
        ARRAY(
            SELECT encode(f.foto, 'base64')
            FROM   tiene_foto as f
            WHERE  f.id_cuenta = id_user
        ),
        ARRAY(
            SELECT o.orientacion_sexual
            FROM   tiene_orientacion_sexual AS o
            WHERE  o.id_cuenta = id_user
        )
    FROM  cuenta, perfil
    WHERE cuenta.id_cuenta = perfil.id_cuenta AND cuenta.id_cuenta = id_user;
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_new_tier_with_new_permissions
* 
* Uso: Insertar una nueva tier a la base de datos con sus nuevos permisos.
*
* Parámetros:
*  - t_nombre                 : nombre de la nueva tier.
*  - p_nombre_permisos[]      : lista de TEXT de nombres de nuevos permisos.
*  - p_descripcion_permisos[] : Lista de TEXT de descripciones de nuevos permisos.
*
* Retorno: Nada.
*/
CREATE OR REPLACE FUNCTION insert_new_tier_with_new_permissions(t_nombre TEXT, p_nombre_permisos TEXT[], p_descripcion_permisos TEXT[])
RETURNS VOID AS $$
DECLARE
    nombre_permisos_size      INT;
    descripcion_permisos_size INT;
    i                         INT;
BEGIN
    /* verificar que el size de las listas sean iguales */
    nombre_permisos_size      := array_length(p_nombre_permisos, 1);
    descripcion_permisos_size := array_length(p_descripcion_permisos, 1);

    IF nombre_permisos_size != descripcion_permisos_size THEN
        RAISE EXCEPTION 'El tamaño de las listas de permisos y descripciones no son iguales';
    END IF;

    /* Insertar el nuevo tier a la bd */
    INSERT INTO tier VALUES(t_nombre);

    /* Insertar cada permiso con su tier en maneja  */
    FOR i IN 1..nombre_permisos_size LOOP
        /* Insertar el permiso en permiso */
        INSERT INTO permiso VALUES(p_nombre_permisos[i], p_descripcion_permisos[i]);

        /* Insertar el permiso en maneja */
        INSERT INTO maneja VALUES(t_nombre, p_nombre_permisos[i]);
    END LOOP;
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_new_tier_with_old_permissions
* 
* Uso: Insertar una nueva tier a la base de datos con permisos ya existente en la base de datos.
*
* Parámetros:
*  - t_nombre            : Nombre de la nueva tier.
*  - p_nombre_permisos[] : Lista de TEXT de nombres de permisos.
*
* Retorno: Nada.
*/
CREATE OR REPLACE FUNCTION insert_new_tier_with_old_permissions(t_nombre TEXT, p_nombre_permisos TEXT[])
RETURNS VOID AS $$
DECLARE
    nombre_permisos_size INT;
    i                    INT;
BEGIN
    nombre_permisos_size := array_length(p_nombre_permisos, 1);

    /* Insertar el nuevo tier a la bd */
    INSERT INTO tier VALUES(t_nombre);

    /* Insertar cada permiso con su tier en maneja  */
    FOR i IN 1..nombre_permisos_size LOOP
        /* Insertar el permiso en maneja */
        INSERT INTO maneja VALUES(t_nombre, p_nombre_permisos[i]);
    END LOOP;
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_new_permission
*
* Uso: insertar un nuevo permiso a la base de datos y asociarlo con un tier.
* 
* Parámetros: 
*  - p_nombre_permiso      : Nombre del permiso.
*  - p_descripcion_permiso : Descripcion del permiso.
*  - p_nombre_tier         : Nombre del tier asociado.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_new_permission(p_nombre_permiso TEXT, p_descripcion_permiso TEXT, p_nombre_tier TEXT) RETURNS VOID AS $$
BEGIN
    INSERT INTO permiso VALUES (p_nombre_permiso, p_descripcion_permiso);
    INSERT INTO maneja  VALUES (p_nombre_tier, p_nombre_permiso);
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_trabaja_en
*
* Uso: Cuando el usuario quiere agregar en que empresa trabaja actualmente, se inserta una nueva instancia de empresa (si es que no existe en la bd) y se inserta una nueva instancia de trabaja_en.
* 
* Parámetros: 
*  - id_user          : Entero del id de la cuenta del usuario.
*  - e_nombre_empresa : TEXT con el nombre de la empresa.
*  - e_url_empresa    : TEXT con el url de la empresa.
*  - e_puesto         : TEXT con el cargo del usuario en la empresa.
*  - e_fecha_inicio   : DATE con la fecha de inicio en que trabaja en la empresa.
*
* Retorno: Nada.
*/
CREATE OR REPLACE FUNCTION insert_trabaja_en(id_user INT, e_nombre_empresa TEXT, e_url_empresa TEXT, e_puesto TEXT, e_fecha_inicio DATE) 
RETURNS VOID AS $$
DECLARE
    e_id_empresa INT;
BEGIN
    -- Buscar si la empresa ya existe
    SELECT id_empresa INTO e_id_empresa FROM empresa WHERE nombre_empresa = e_nombre_empresa AND url = e_url_empresa;
    IF NOT FOUND THEN
        -- Si no existe, insertar una nueva instancia de empresa
        INSERT INTO empresa(nombre_empresa, url) VALUES(e_nombre_empresa, e_url_empresa);
        SELECT id_empresa INTO e_id_empresa FROM empresa WHERE nombre_empresa = e_nombre_empresa AND url = e_url_empresa;
    END IF;

    -- Insertar una nueva instancia de trabaja_en
    INSERT INTO trabaja_en VALUES(id_user, e_id_empresa, e_puesto, e_fecha_inicio);
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_agrupation
*
* Uso: Insertar una agrupacion de un usuario en una institucion en la tabla esta_en_agrupacion.
*
* Parámetros:
*  - p_id_cuenta  : Entero del id de la cuenta de un usuario.
*  - p_id_dominio : TEXT dominio de una institucion.
*  - p_agrupacion : TEXT de la agrupacion a insertar.
*
* Retorna: Nada.
*/

CREATE OR REPLACE FUNCTION insert_agrupation(p_id_cuenta integer, p_id_dominio TEXT, p_agrupacion TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO esta_en_agrupacion(id_cuenta, dominio, agrupacion)
    VALUES (p_id_cuenta, p_id_dominio, p_agrupacion);
END;
$$ LANGUAGE plpgsql;


/* 
* Función: get_all_info_about_a_user_estudio_en
* 
* Uso: Obtener todos los datos  (grados academicos con sus especialidades, años de ingreso y egreso, y agrupaciones) de estudio_en dado por su dominio de institucion e id_cuenta.
*
* Parámetros: 
*  - p_id_cuenta  : Entero del id de la cuenta de un usuario.
*  - p_id_dominio : TEXT dominio de una institucion.
*
* Retorno: Una tabla de una fila con los datos de estudio_en asociados a la id_cuenta = p_id_cuenta y dominio = p_id_dominio.
*/
CREATE OR REPLACE FUNCTION get_all_info_about_a_user_estudio_en(p_id_cuenta integer, p_id_dominio TEXT)
RETURNS TABLE(
    r_grado        CHARACTER VARYING[], 
    r_especialidad CHARACTER VARYING[], 
    r_ano_ingreso  INTEGER[], 
    r_ano_egreso   INTEGER[], 
    agrupaciones   CHARACTER VARYING[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT array_agg(grado), array_agg(especialidad), array_agg(ano_ingreso), array_agg(ano_egreso), 
    ARRAY(
        SELECT a.agrupacion 
        FROM   esta_en_agrupacion AS a
        WHERE  a.id_cuenta = p_id_cuenta AND a.dominio = p_id_dominio
    )
    FROM (
        SELECT *
        FROM   estudio_en
        WHERE  id_cuenta = p_id_cuenta AND dominio = p_id_dominio
    ) GROUP BY dominio;
END;
$$ LANGUAGE plpgsql;


/* 
* Función: get_all_info_about_a_user_trabaja_en
* 
* Uso: Obtener todos los datos de trabaja_en (cargo y fechas de inicio) de un usuario en una empresa.
*
* Parámetros: 
*  - p_id_cuenta  : Entero del id de la cuenta de un usuario.
*  - p_id_empresa : Entero del id de la empresa en que trabaja.
*
* Retorna: Una tabla de una fila con los datos de trabaja_en asociados a la id_cuenta = p_id_cuenta y id_empresa = p_id_empresa.
*/
CREATE OR REPLACE FUNCTION get_all_info_about_a_user_trabaja_en(p_id_cuenta integer, p_id_empresa integer)
RETURNS TABLE(puesto CHARACTER VARYING, fecha_de_inicio DATE) AS $$
BEGIN
    RETURN QUERY
    SELECT cargo, fecha_inicio
    FROM   trabaja_en
    WHERE  id_cuenta = p_id_cuenta AND id_empresa = p_id_empresa;
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_all_info_about_a_empresa
*
* Uso: Obtener toda la informacion de una empresa (url y nombre).
*
* Parámetros:
*   - idEmpresa: Entero del id de la empresa.
*
* Resultado: Tabla de una fila con el nombre y url de la empresa.
*/
CREATE OR REPLACE FUNCTION get_all_info_about_a_empresa(idEmpresa integer)
RETURNS TABLE(nombreEmpresa CHARACTER VARYING, urlEmpresa CHARACTER VARYING) AS $$
BEGIN
    RETURN QUERY
    SELECT nombre_empresa, url
    FROM   empresa
    WHERE  id_empresa = idEmpresa;
END;
$$ LANGUAGE plpgsql;


/* 
* Función: update_visto_msj
* 
* Uso: Actualizar el true del visto de un mensaje en la tabla mensaje.
*
* Parámetros: 
*  - p_id_chat     : entero que representa el id del chat.
*  - p_nro_mensaje : entero que representa el nro del mensaje en el chat.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_visto_msj(p_id_chat integer, p_nro_mensaje integer) 
RETURNS VOID AS $$
BEGIN
    UPDATE mensaje
    SET    visto = TRUE
    WHERE  id_chat = p_id_chat AND numero_msj = p_nro_mensaje;
END;
$$ LANGUAGE plpgsql;


/* 
* Función: insert_hobbies
*
* Uso: Inserta un nuevo registro en la tabla tiene_hobby.
*
* Parámetros:
*  - p_user_id : Entero del id de la cuenta.
*  - p_hobby   : TEXT del hobby.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_hobbies(p_user_id INTEGER, p_hobby TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_hobby (id_cuenta, hobby)
    VALUES (p_user_id, p_hobby);
END;
$$ LANGUAGE plpgsql;

/* 
* Función: insert_habilidad
*
* Uso: Inserta un nuevo registro en la tabla tiene_habilidades.
*
* Parámetros:
*  - p_user_id   : Entero del id de la cuenta.
*  - p_habilidad : TEXT del habilidad.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_habilidades(p_user_id INTEGER, p_habilidad TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_habilidades (id_cuenta, habilidad)
    VALUES (p_user_id, p_habilidad);
END;
$$ LANGUAGE plpgsql;


/* 
* Función: insert_foto
*
* Uso: Inserta un nuevo registro en la tabla tiene_foto.
*
* Parámetros:
*  - p_user_id : Entero del id de la cuenta.
*  - p_foto    : TEXT de la foto en formato base64.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_foto(p_user_id INTEGER, p_foto TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_foto (id_cuenta, foto) VALUES (p_user_id, decode(p_foto, 'base64'));
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_certificacion
*
* Uso: Inserta un nuevo registro en la tabla tiene_certificaciones.
*
* Parámetros:
*  - p_user_id       : Entero del id de la cuenta.
*  - p_certificacion : TEXT de la certificacion.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_certificacion(p_user_id INTEGER, p_certificacion TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_certificaciones (id_cuenta, certificaciones) VALUES (p_user_id, p_certificacion);
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_orientacion_sexual_perfil
*
* Uso: Inserta un nuevo registro en la tabla tiene_orientacion_sexual.
*
* Parámetros:
*  - p_user_id            : Entero del id de la cuenta.
*  - p_orientacion_sexual : TEXT de la orientacion sexual.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_orientacion_sexual_perfil(p_user_id INTEGER, p_orientacion_sexual TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_orientacion_sexual (id_cuenta, orientacion_sexual)
    VALUES (p_user_id, p_orientacion_sexual);
END;
$$ LANGUAGE plpgsql;


/* 
* Función: delete_hobby
*
* Uso: Eliminar una instancia en tiene_hobby dado el id_cuenta de un usuario.
*
* Parámetros:
*   - p_user_id : Entero del id de la cuenta.
*   - p_hobby   : TEXT del hobby.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_hobby(p_user_id INTEGER, p_hobby TEXT) 
RETURNS VOID AS $$
BEGIN
    DELETE FROM tiene_hobby
    WHERE id_cuenta = p_user_id AND hobby = p_hobby;
END;
$$ LANGUAGE plpgsql;


/*
* Función: delete_habilidad
*
* Uso: Eliminar una instancia en tiene_habilidades dado el id_cuenta de un usuario.
*
* Parámetros:
*   - p_user_id   : Entero del id de la cuenta.
*   - p_habilidad : TEXT de la habilidad.
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION delete_habilidad(p_user_id INTEGER, p_habilidad TEXT) RETURNS VOID AS $$
BEGIN
    DELETE FROM tiene_habilidades
    WHERE id_cuenta = p_user_id AND habilidad = p_habilidad;
END;
$$ LANGUAGE plpgsql;

/*
* Función: delete_foto
*
* Uso: Eliminar una instancia en tiene_foto dado el id_cuenta de un usuario, pero si es la unica foto que queda no se elimina.
*
* Parámetros:
*   - p_user_id : Entero del id de la cuenta.
*   - p_id_foto : Entero del id de la foto a eliminar.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_foto(p_user_id INTEGER, p_id_foto INTEGER)
RETURNS VOID AS $$
DECLARE
    cant_fotos INTEGER;
BEGIN
    SELECT COUNT(*) INTO cant_fotos
    FROM tiene_foto
    WHERE id_cuenta = p_user_id;

    IF cant_fotos > 1 THEN
        DELETE FROM tiene_foto
        WHERE id_cuenta = p_user_id AND id_foto = p_id_foto;
    ELSE
        RAISE EXCEPTION 'No se puede eliminar la unica foto';
    END IF;
END;
$$ LANGUAGE plpgsql;


/*
* Función: delete_certificacion
*
* Uso: Eliminar una instancia en tiene_certificacion dado el id_cuenta de un usuario.
*
* Parámetros:
*   - p_user_id       : Entero del id de la cuenta.
*   - p_certificacion : TEXT de la certificacion.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_certificacion(p_user_id INTEGER, p_certificacion TEXT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM tiene_certificaciones
    WHERE id_cuenta = p_user_id AND certificaciones = p_certificacion;
END;
$$ LANGUAGE plpgsql;


/*
* Función: delete_orientacion_sexual_perfil
*
* Uso: Eliminar una instancia en tiene_orientacion_sexual dado el id_cuenta de un usuario.
*
* Parámetros:
*   - p_user_id            : Entero del id de la cuenta.
*   - p_orientacion_sexual : TEXT de la orientacion sexual.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_orientacion_sexual_perfil(p_user_id INTEGER, p_orientacion_sexual TEXT) 
RETURNS VOID AS $$
BEGIN
    DELETE FROM tiene_orientacion_sexual
    WHERE id_cuenta = p_user_id AND orientacion_sexual = p_orientacion_sexual;
END;
$$ LANGUAGE plpgsql;


/*
* Función: update_institution
*
* Uso: modificar el nombre, tipo o año de fundacion de una institucion.
*
* Parámetros:
*   - p_dominio       : TEXT dominio de la institucion a modificar.
*   - p_nombre        : (OPCIONAL) TEXT nombre de la institucion.
*   - p_tipo          : (OPCIONAL) TEXT tipo de la institucion.
*   - p_ano_fundacion : (OPCIONAL) entero del año de fundacion de la institucion (por si se equivoco al principio colocarlo).
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_institution(
    p_dominio       TEXT, 
    p_nombre        TEXT DEFAULT NULL, 
    p_tipo          TEXT DEFAULT NULL, 
    p_ano_fundacion INTEGER DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    IF p_nombre IS NOT NULL THEN
        UPDATE institucion SET nombre = p_nombre WHERE dominio = p_dominio;
    END IF;
    IF p_tipo IS NOT NULL THEN
        UPDATE institucion SET tipo = p_tipo WHERE dominio = p_dominio;
    END IF;
    IF p_ano_fundacion IS NOT NULL THEN
        UPDATE institucion SET ano_fundacion = p_ano_fundacion WHERE dominio = p_dominio;
    END IF;
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_pago()
*
* Uso: Insertar un pago en la tabla pago.
*
* Parámetros: 
*   - p_nro_factura : Valor entero de la factura del pago.
*   - p_estado      : BOOLEAN que indica el estado del pago (TRUE si es aprobado y False si es fallido).
*   - p_metodo      : TEXT metodo del pago.
*   - p_monto       : DECIMAL Monto del pago.
*   - p_doc_factura : TEXT documento de la factura en formato base64.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_pago(
    p_nro_factura INTEGER,
    p_estado      BOOLEAN,
    p_metodo      TEXT, 
    p_monto       DECIMAL, 
    p_doc_factura TEXT
) RETURNS VOID AS $$
BEGIN
    INSERT INTO pago(numero_factura, estado, metodo, monto, documento_factura)
    VALUES (p_nro_factura, p_estado, p_metodo, p_monto, decode(p_doc_factura, 'base64'));
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_data_pago()
*
* Uso: Obtener todos los datos de un pago.
*
* Parámetros: 
*    - p_id_pago : Entero ID del pago.
*
* Retorno: Devuelve un registro con todos los datos del pago.
*/
CREATE OR REPLACE FUNCTION get_data_pago(p_id_pago integer)
RETURNS TABLE(
    r_id_pago           INTEGER,
    r_numero_factura    INTEGER,
    r_estado            BOOLEAN,
    r_metodo            metodo_pago,
    r_monto             NUMERIC,
    r_fecha             DATE,
    r_documento_factura TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        id_pago,
        numero_factura,
        estado,
        metodo,
        monto,
        fecha,
        encode(documento_factura, 'base64')
    FROM pago
    WHERE id_pago = p_id_pago;
END;
$$ LANGUAGE plpgsql;


/*
* Función: check_if_user_has_a_permission
*
* Uso: Verificar si un usuario tiene un permiso en particular.
*
* Parámetros:
*  - user_id         : Valor entero del Id de la cuenta del usuario.
*  - permission_name : Valor texto del nombre del permiso que se desea verificar.
*
* Retorno: Retorna un valor booleano que indica si el usuario tiene el permiso o no.
*/
CREATE OR REPLACE FUNCTION check_if_user_has_a_permission(user_id integer, permission_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    permission_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM maneja
        WHERE nombre_permiso = permission_name
            AND nombre_tier IN (
                SELECT nombre_tier FROM suscrita
                WHERE  id_cuenta = user_id
                AND    fecha_caducidad > CURRENT_DATE
            )
    ) INTO permission_exists;

    RETURN permission_exists;
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_all_users_by_10km_radius
*
* Uso: Obtener todos los IDs de los usuarios que se encuentren alrededor de 10 km de una coordenada de origen dada.
*
* Parámetros:
*  - user_id : Valor entero del Id de la cuenta del usuario que desea encontrar a las otras personas por su coordenada origen de preferencias.
*
* Retorno: Retorna una tabla con los IDs de los usuarios que se encuentren en esa coordenada de origen dada y dentro de 10 km de radio.
*/
CREATE OR REPLACE FUNCTION get_all_users_by_10km_radius(user_id integer)
RETURNS TABLE(r_id_cuenta integer) AS $$
BEGIN
    RETURN QUERY
    SELECT id_cuenta FROM perfil
    WHERE  ST_DistanceSphere(
            coordenada,
            (SELECT coordenada_origen FROM preferencias WHERE id_cuenta = user_id)
        ) / 1000 <= 10 -- 10 km in meters
        AND id_cuenta != user_id
    ORDER BY ST_DISTANCE(coordenada, (SELECT coordenada_origen FROM preferencias WHERE id_cuenta = user_id));
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_users_by_preferences_passport_user
*
* Uso: Obtener los ids cuentas de los usuarios que se encuentra en una ciudad (por coordenada origen en preferencias)
* y que cumplen con las preferencias de estudio, min y max edad, sexos y orientaciones sexuales de otro usuario.
*
* Parámetros:
*  - user_id : id del usuario que tiene las preferencias y con permiso passport.
*
* Retorno: Tabla con los ids de las cuentas de los usuarios que cumplen con las preferencias.
*/
CREATE OR REPLACE FUNCTION get_users_by_preferences_passport_user(user_id integer)
RETURNS TABLE(pref_id_cuentas integer) AS $$
DECLARE
    pref_estudio     TEXT;
    pref_min_age     INTEGER;
    pref_max_age     INTEGER;
    pref_genre       TEXT[];
    pref_orientation TEXT[];
BEGIN
    SELECT min_edad, max_edad, estudio
    INTO   pref_min_age, pref_max_age, pref_estudio
    FROM   preferencias
    WHERE  id_cuenta = user_id;

    SELECT array_agg(sexo)
    INTO   pref_genre
    FROM   pref_sexo
    WHERE  id_cuenta = user_id;

    SELECT array_agg(orientacion_sexual)
    INTO   pref_orientation
    FROM   pref_orientacion_sexual
    WHERE  id_cuenta = user_id;

    RETURN QUERY
    SELECT id_cuenta
    FROM   cuenta
    WHERE  id_cuenta != user_id
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_estudio(pref_estudio))
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_min_age(pref_min_age))
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_max_age(pref_max_age))
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_genre(pref_genre))
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_users_by_orientation_sexual(pref_orientation))
        AND id_cuenta IN (SELECT id_cuenta_at_max_distance FROM get_all_users_by_10km_radius(user_id));
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_chats_by_user
*
* Uso: Obtener los ids chats que participa un usuario.
*
* Parámetros:
*  - user_id : Id del usuario.
*
* Retorno: Tabla con los ids de los chats
*/
CREATE OR REPLACE FUNCTION get_chats_by_user(user_id integer)
RETURNS TABLE (r_id_chat integer) AS $$
BEGIN
    RETURN QUERY
    SELECT id_chat 
    FROM   chatea_con
    WHERE  id_cuenta1 = user_id OR id_cuenta2 = user_id;
END;
$$ LANGUAGE plpgsql;


/*
* Function insert_like()
*
* Uso: Para agregar un nuevo like a la tabla de likes.
*
* Parámetros: 
*	- liker     : Id de quien da like.
*	- liked     : Id de quien recibe el like.
*	- superlike : True si fue un superlike, false en caso contrario.
*
* Retorna: nada.
*/
CREATE OR REPLACE FUNCTION insert_like(liker INT, liked INT, superlike BOOL DEFAULT FALSE) 
RETURNS VOID AS $$
BEGIN
	INSERT INTO likes(id_liker, id_liked, super) VALUES (liker, liked, superlike);
END; 
$$ LANGUAGE plpgsql;


/*
* Function insert_swipe()
*
* Uso: Para agregar un nuevo dislike a la tabla de swipes.
*
* Parámetros: 
*	- disliker : Id de quien da dislike.
*	- disliked : Id de quien recibe el dislike.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_swipe(disliker INT, disliked INT)
	RETURNS VOID AS $$
BEGIN
	INSERT INTO swipes(id_disliker, id_disliked) VALUES (disliker, disliked);
END;
$$ LANGUAGE plpgsql;


/*
* Function delete_like()
*
* Uso: Para que un usuario elimine un like que dio anteriormente
*	   con la condicion de que dicho usuario debe estar suscrito a un tier.
*
* Parámetros: 
*	- id_user  : Id de quien elimina el like.
*	- disliked : Id de quien se borra el like.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_like(id_user INT, disliked INT)
RETURNS VOID AS $$
BEGIN
	IF EXISTS( SELECT 1 FROM suscrita WHERE id_cuenta = id_user AND fecha_caducidad > CURRENT_DATE ) THEN
		DELETE FROM likes WHERE id_liker = id_user AND id_liked = disliked;
	ELSE
		RAISE EXCEPTION 'El usuario no está suscrito a ningún tier.';
	END IF;
END;
$$ LANGUAGE plpgsql;


/*
* Function insert_match()
*
* Uso: Agregar un match en caso de que dos usuarios se den like mutuamente
*	   y crear un chat entre ambos.
* Parámetros: 
*	- id_user1: Id de uno de los dos usuarios del match.
*	- id_user2: Id de uno de los dos usuarios del match.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_match(id_user1 INT, id_user2 INT)
	RETURNS VOID AS $$
DECLARE
	fecha_user1 TIMESTAMP;
	fecha_user2 TIMESTAMP;
	new_chat_id INT;
BEGIN 	
	SELECT fecha_like INTO fecha_user1
	FROM   likes 
	WHERE  id_liker = id_user1 AND id_liked = id_user2;

	SELECT fecha_like INTO fecha_user2
	FROM   likes
	WHERE  id_liker= id_user2 AND id_liked = id_user1;

	INSERT INTO chat DEFAULT VALUES RETURNING id_chat INTO new_chat_id;

	IF fecha_user1 < fecha_user2 THEN 
		INSERT INTO match_with(id_matcher, id_matched) VALUES (id_user1, id_user2);
		INSERT INTO chatea_con(id_cuenta1, id_cuenta2, id_chat) VALUES (id_user1, id_user2, new_chat_id);
	ELSIF fecha_user1 > fecha_user2 THEN
		INSERT INTO match_with(id_matcher, id_matched) VALUES (id_user2, id_user1);
		INSERT INTO chatea_con(id_cuenta1, id_cuenta2, id_chat) VALUES (id_user2, id_user1, new_chat_id);
	END IF;
END;
$$ LANGUAGE plpgsql;


/*
* Function subscribe_user()
*
* Uso: Realiza la suscripción de un usuario a un tier y gestiona el proceso de pago.
*
* Parámetros: 
*   - id_cuenta_usuario         : ID de la cuenta del usuario que desea suscribirse.
*   - nombre_tier_usuario       : Nombre del tier al que desea suscribirse el usuario.
*   - caducidad                 : Fecha de caducidad de la suscripción.
*   - digitos_tarjeta_usario    : Dígitos de la tarjeta de crédito del usuario para el pago.
*   - numero_factura_actual     : Número de factura del pago.
*   - estado_pago               : Estado del pago (TRUE si está aprobado, FALSE si está pendiente o rechazado).
*   - metodo_pago_usuario       : Método de pago utilizado por el usuario (ej. Tarjeta de Crédito).
*   - monto_pago                : Monto del pago realizado.
*   - documento_factura_usuario : Documento de la factura en formato BYTEA.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION subscribe_user(
    id_cuenta_usuario         INT,
    nombre_tier_usuario       TEXT,
    caducidad                 TIMESTAMP,
    digitos_tarjeta_usario    TEXT,
    numero_factura_actual     INT,
    estado_pago               BOOLEAN,
    metodo_pago_usuario       TEXT,
    monto_pago                DECIMAL(10,2),
    documento_factura_usuario BYTEA
) RETURNS VOID AS $$
DECLARE
    new_id_pago INT;
BEGIN
    -- Verificar si la cuenta y la tarjeta existen y si el tier está disponible
    IF NOT EXISTS (SELECT 1 FROM cuenta WHERE id_cuenta = id_cuenta_usuario) THEN
        RAISE EXCEPTION 'La cuenta con id % no existe', id_cuenta_usuario;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tarjeta WHERE digitos_tarjeta = digitos_tarjeta_usario) THEN
        RAISE EXCEPTION 'La tarjeta con dígitos % no existe', digitos_tarjeta_usario;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tier WHERE nombre_tier = nombre_tier_usuario) THEN
        RAISE EXCEPTION 'El tier % no existe', nombre_tier_usuario;
    END IF;

    -- Verificar si el usuario ya está suscrito a un tier activo
    IF EXISTS (
        SELECT 1 FROM suscrita
        WHERE  id_cuenta = id_cuenta_usuario
          AND  fecha_caducidad > CURRENT_TIMESTAMP
    ) THEN
        RAISE EXCEPTION 'El usuario ya está suscrito a un tier activo';
    END IF;

    -- Verificar que la fecha de caducidad sea mayor que la fecha actual
    IF caducidad <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'La fecha de caducidad debe ser en el futuro';
    END IF;

    -- Insertar el pago
    INSERT INTO pago (numero_factura, estado, metodo, monto, documento_factura)
    VALUES (numero_factura_actual, estado_pago, metodo_pago_usuario, monto_pago, documento_factura_usuario)
    RETURNING id_pago INTO new_id_pago;

    -- Insertar en realiza
    INSERT INTO realiza (id_cuenta, id_pago, digitos_tarjeta)
    VALUES (id_cuenta_usuario, new_id_pago, digitos_tarjeta_usario);

    -- Si el pago está aprobado, insertar en suscrita
    IF estado_pago THEN
        INSERT INTO suscrita (id_cuenta, nombre_tier, fecha_inicio, fecha_caducidad)
        VALUES (id_cuenta_usuario, nombre_tier_usuario, CURRENT_DATE, caducidad);
    END IF;
END;
$$ LANGUAGE plpgsql;


/*    
* Función: check_match_exists
*
* Uso: Chequear si dos personas dieron like el uno al otro.
*
* Parámetros: Ninguna.
*
* Retorno: Función trigger que crea un match y un chat entre dos usuarios que dieron likes el uno al otro.
*/
CREATE OR REPLACE FUNCTION check_match_exists()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM likes WHERE id_liker = NEW.id_liker AND id_liked = NEW.id_liked) AND
    EXISTS (SELECT 1 FROM likes WHERE  id_liker= NEW.id_liked AND id_liked = NEW.id_liker) THEN
        PERFORM insert_match(NEW.id_liker, NEW.id_liked);   
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
* Función: cancel_match
*
* Uso: Eliminar el match entre dos usuarios, eliminando tambien el chat y los likes 
*      que se hayan dado entre ellos. Ademas, ya al eliminar el chat se elimina los mensajes y la instancia
*      de chatea_con.
*
* Parámetros:
*    - id_user_canceling : INT del usuario que cancela el match.
*    - id_user_canceled  : INT del usuario que se cancela el match.
*
* Retorno: Nada.
*/
CREATE OR REPLACE FUNCTION cancel_match(id_user_canceling INT, id_user_canceled INT)
RETURNS VOID AS $$
DECLARE 
    id_their_chat INTEGER;
BEGIN
    DELETE FROM match_with WHERE id_matcher = id_user_canceling AND id_matched = id_user_canceled;
    DELETE FROM match_with WHERE id_matcher = id_user_canceled AND id_matched = id_user_canceling;
    id_their_chat := (
        SELECT id_chat FROM chatea_con WHERE 
        (id_cuenta1 = id_user_canceling AND id_cuenta2 = id_user_canceled) OR 
        (id_cuenta1 = id_user_canceled AND id_cuenta2 = id_user_canceling)
    );
    DELETE FROM chat WHERE id_chat = id_their_chat;

    DELETE FROM likes WHERE id_liker = id_user_canceling AND id_liked = id_user_canceled;
    DELETE FROM likes WHERE id_liker = id_user_canceled AND id_liked = id_user_canceling;
END;
$$ LANGUAGE plpgsql;


/*
* Function get_number_of_likes()
*
* Uso: Calcular el numero de likes que ha recibido una persona.
*	
* Parámetros: 
*	- id_user : Id de uno del usuario.
*	
* Retorna: Entero que representa el total de likes.
*/
CREATE OR REPLACE FUNCTION get_number_of_likes(id_user INT)
RETURNS INTEGER AS $$
DECLARE
	num_likes INTEGER;
BEGIN
	SELECT COUNT(*) INTO num_likes
	FROM   likes
	WHERE  id_liked = id_user;

	RETURN num_likes;
END;
$$LANGUAGE plpgsql;


/*
* Function get_likes_per_day()
*
* Uso: Calcular el numero de likes que da un usuario al dia.
*
* Parámetros: 
*	- id_user  : Id del usuario a calcular.
*	- from_day : Fecha a buscar.
*
* Retorna: Entero que representa el numero de likes dados en un dia.
*/

CREATE OR REPLACE FUNCTION get_likes_per_day(id_user INTEGER, from_day DATE)
RETURNS INTEGER AS $$
DECLARE
	likes_per_day INTEGER;
BEGIN
	SELECT COUNT(*) INTO likes_per_day
	FROM   likes 
	WHERE  id_liker = id_user AND DATE(fecha_like) = from_day;

	RETURN likes_per_day;
END;
$$ LANGUAGE plpgsql;

/*
* Función: delete_cuenta
*
* Uso: Elimina una cuenta.
*
* Parámetros:
*  - p_id_cuenta : Valor entero del ID de la cuenta del usuario a eliminar.
*
* Retorna: Nada.
*/

CREATE OR REPLACE FUNCTION delete_cuenta(p_id_cuenta INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM cuenta WHERE id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;


/*
* Function update_tier_of_user()
*
* Uso: Actualiza el tier de un usuario en función de una nueva suscripción y registra el pago asociado.
*
* Parámetros: 
*   - id_cuenta_usuario         : ID de la cuenta del usuario.
*   - nueva_tier_usuario        : Nombre del nuevo tier al que se quiere suscribir al usuario.
*   - digitos_tarjeta_usario    : Últimos dígitos de la tarjeta del usuario.
*   - numero_factura_actual     : Número de la factura actual.
*   - estado_pago               : Estado del pago (TRUE si el pago fue exitoso, FALSE en caso contrario).
*   - metodo_pago_usuario       : Método de pago utilizado.
*   - monto_pago                : Monto del pago.
*   - documento_factura_usuario : Documento de la factura en formato BYTEA.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_tier_of_user(
    id_cuenta_usuario         INT,
    nueva_tier_usuario        TEXT,
    digitos_tarjeta_usario    TEXT,
    numero_factura_actual     INT,
    estado_pago               BOOLEAN,
    metodo_pago_usuario       TEXT,
    monto_pago                DECIMAL(10,2),
    documento_factura_usuario BYTEA
) RETURNS VOID AS $$
DECLARE
    new_id_pago                INT;
    current_tier               TEXT;
    cantidad_vieja_de_permisos INT;
    cantidad_nueva_de_permisos INT;
BEGIN
    -- Verificar si la cuenta y la tarjeta existen y si el tier está disponible
    IF NOT EXISTS (SELECT 1 FROM cuenta WHERE id_cuenta = id_cuenta_usuario) THEN
        RAISE EXCEPTION 'La cuenta con id % no existe', id_cuenta_usuario;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tarjeta WHERE digitos_tarjeta = digitos_tarjeta_usario) THEN
        RAISE EXCEPTION 'La tarjeta con dígitos % no existe', digitos_tarjeta_usario;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tier WHERE nombre_tier = nueva_tier_usuario) THEN
        RAISE EXCEPTION 'El tier % no existe', nueva_tier_usuario;
    END IF;

    -- Verificar si el usuario está suscrito a un tier activo
    IF NOT EXISTS (
        SELECT tier INTO current_tier FROM suscrita
        WHERE  id_cuenta = id_cuenta_usuario
            AND fecha_caducidad > CURRENT_TIMESTAMP
    ) THEN
        RAISE EXCEPTION 'El usuario no está suscrito a un tier activo';
    END IF;

    SELECT COUNT(*) INTO cantidad_vieja_de_permisos
    FROM   maneja
    WHERE  nombre_tier = current_tier;

    SELECT COUNT(*) INTO cantidad_nueva_de_permisos
    FROM   maneja
    WHERE  nombre_tier = nueva_tier_usuario;    

    -- Definir el orden de los tiers
    IF (cantidad_nueva_de_permisos > cantidad_vieja_de_permisos) THEN
       
        INSERT INTO pago (numero_factura, estado, metodo_pago, monto, documento_factura)
        VALUES (numero_factura_actual, estado_pago, metodo_pago_usuario, monto_pago, documento_factura_usuario)
        RETURNING id_pago INTO new_id_pago;

        INSERT INTO realiza (id_cuenta, id_pago, digitos_tarjeta)
        VALUES (id_cuenta_usuario, new_id_pago, digitos_tarjeta_usario);

        IF estado_pago THEN
            UPDATE suscrita
            SET    tier = nueva_tier_usuario
            WHERE  id_cuenta = id_cuenta_usuario
                AND fecha_caducidad > CURRENT_TIMESTAMP;
        END IF;

    ELSE
        RAISE EXCEPTION 'El nuevo tier % no es superior al tier actual %', nueva_tier_usuario, current_tier;
    END IF;
END;
$$ LANGUAGE plpgsql;


/*    
* Función: prohibir_101_likes
*
* Uso: prohibir dar mas de 100 likes al dia si no tiene el permiso infLikes
*
* Parámetros: Ninguna
*
* Resultado: Función trigger que no permite dar mas de 100 likes al dia si no tiene el permiso infLikes
*/

CREATE OR REPLACE FUNCTION prohibir_101_likes()
RETURNS TRIGGER AS $$
BEGIN
    IF (get_likes_per_day(New.id_liker, CURRENT_DATE)) = 100 THEN
        IF (check_if_user_has_a_permission(New.id_liker, 'infLikes')) = FALSE THEN
            RAISE EXCEPTION 'No puedes dar mas de 100 likes al dia';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*
* Function add_tier_with_permission()
*
* Uso: Agrega un nuevo tier a la tabla de tier y le asigna al menos un permiso en la tabla maneja.
* 
* Parámetros: 
*   - nombre_nuevo_tier : Nombre del nuevo tier a agregar.
*   - nombre_permisos   : Lista de nombres de permisos a asignar al nuevo tier.
*
* Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION add_tier_with_permission(
    nombre_nuevo_tier VARCHAR(16),
    nombre_permisos   TEXT[]
) RETURNS VOID AS $$
BEGIN
    -- Verificar si el tier ya existe
    IF EXISTS (SELECT 1 FROM tier WHERE nombre_tier = nombre_nuevo_tier) THEN
        RAISE EXCEPTION 'El tier % ya existe', nombre_nuevo_tier;
    END IF;

    -- Insertar el nuevo tier
    INSERT INTO tier (nombre_tier) VALUES (nombre_nuevo_tier);

    -- Verificar que se haya proporcionado al menos un permiso
    IF array_length(nombre_permisos, 1) IS NULL OR array_length(nombre_permisos, 1) = 0 THEN
        RAISE EXCEPTION 'Debe proporcionar al menos un permiso para el tier %', nombre_nuevo_tier;
    END IF;

    -- Asignar los permisos al nuevo tier
    FOR i IN 1..array_length(nombre_permisos, 1) LOOP
        -- Verificar si el permiso existe
        IF NOT EXISTS (SELECT 1 FROM permiso WHERE nombre_permiso = nombre_permisos[i]) THEN
            RAISE EXCEPTION 'El permiso % no existe', nombre_permisos[i];
        END IF;

        -- Insertar el permiso en la tabla maneja
        INSERT INTO maneja (nombre_tier, nombre_permiso)
        VALUES (nombre_nuevo_tier, nombre_permisos[i]);
    END LOOP;
END;
$$ LANGUAGE plpgsql;


/*
* Función: insert_file
*
* Uso: Crear instancia en la tabla archivo.
* 
* Parámetros: 
*   - chat_id      : Id del chat correspondiente.
*	- name_file    : Nombre del archivo a obtener.
*	- type_file    : Tipo del archivo.
*	- content_file : Contenido del archivo.
*   - remitente_id : Id del remitente.
*
* Retorna: Nada.
*/

CREATE OR REPLACE FUNCTION insert_file(
    chat_id      INT, 
    name_file    TEXT, 
    type_file    TEXT,
    content_file TEXT,
    remitente_id INT
) RETURNS VOID AS $$
DECLARE 
	new_msg_num INT;
BEGIN
	INSERT INTO mensaje (id_remitente) 
	VALUES (remitente_id)
	RETURNING numero_msj INTO new_msg_num;

	INSERT INTO archivo (id_chat, numero_msj, nombre, tipo, contenido )
	VALUES (chat_id, new_msg_num, name_file, type_file, decode(content_file, 'base64'));
END;
$$ LANGUAGE plpgsql;


/*
* Función: get_file
*
* Uso: Obtener archivos.
*
* Parámetros: 
*	- chat_id   : Id del chat correspondiente.
*	- message   : Numero del mensaje correspondiente.
*	- name_file : Nombre del archivo a obtener.
*
* Returno: Tabla con los datos del archivo.
*/

CREATE OR REPLACE FUNCTION get_file(
    chat_id     INT, 
    message_num INT, 
    name_file   TEXT)
RETURNS TABLE(
	msg_num           INT,
	file_name         CHARACTER VARYING,
	tipo_archivo      CHARACTER VARYING,
	contenido_archivo TEXT
) AS $$
BEGIN
	RETURN QUERY
	SELECT numero_msj, nombre, tipo, encode(contenido, 'base64')
	FROM   archivo
	WHERE  id_chat = chat_id AND numero_msj = message_num AND nombre = name_file ;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: insert_old_tier_old_permissions
*
* Uso: Insertar unos permisos existentes a un tier existente en la bd
*
* Parametros: 
*    - old_nombre_tier: nombre de un tier existente
*    - old_permissions: lista de nombre de permisos existentes
*
* Returna: Nada
*/
CREATE OR REPLACE FUNCTION insert_old_tier_old_permissions (
	old_nombre_tier TEXT, 
	old_permissions TEXT[]
)
RETURNS VOID AS $$
DECLARE
    i integer;
BEGIN
    FOR i IN 1..array_length(old_permissions, 1) LOOP
        INSERT INTO maneja (nombre_tier, nombre_permiso)
        VALUES (old_nombre_tier, old_permissions[i]);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: set_null_estudio
*
* Uso: Si el usuario ya no quiere buscar personas por su estudio, se setea null a este atributo en la tabla preferencias
*
* Parametros: 
*    - p_id_cuenta: id de la cuenta del usuario
*
* Returna: Nada
*/
CREATE OR REPLACE FUNCTION set_null_estudio(p_id_cuenta integer)
RETURNS void AS $$
BEGIN
    UPDATE preferencias
    SET estudio = NULL
    WHERE id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: set_default_latitud_longitud_origen
*
* Uso: Si el usuario ya no quiere buscar personas por un punto de coordenada o se termina su suscripcion a un tier con permiso passport, se setea la coordenada origen al valor defecto (que es la coordenada donde esta el usuario) en la tabla preferencias
*
* Parametros: 
*    - p_id_cuenta: id de la cuenta del usuario
*
* Returna: Nada
*/
CREATE OR REPLACE FUNCTION set_default_latitud_longitud_origen(p_id_cuenta integer)
RETURNS void AS $$
BEGIN
    /* se setea null, ya que hay un trigger que setea por default a las coordenadas del usuario */
    UPDATE preferencias
    SET latitud_origen = NULL, longitud_origen = NULL
    WHERE id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;
