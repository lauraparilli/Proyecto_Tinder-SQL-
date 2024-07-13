/* 
    Equipo 1: Tinder para Viejos Egresados (RobbleAffinity)
    
    Integrantes: Ana Shek,         19-10096
			     Jhonaiker Blanco, 18-10784
				 Junior Lara,      17-10303
				 Laura Parilli,    17-10778

                    **** FUNCTIONS.sql ****

    Archivo SQL de creacion de funciones para la BD de Tinder para Viejos Egresados.
*/

/*********************************************************************************************/
/*
    Función:
        prevent_delete_any_row

    Uso: 
        Prohibir eliminar una fila de una tabla (ejemplo una institucion).

    Parámetros: 
        Ninguna.

    Resultado: 
        Función trigger que evita que se elimine una fila de una tabla.
*/
CREATE OR REPLACE FUNCTION prevent_delete_any_row()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Prohibido eliminar una fila de esta tabla.';
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        set_coordenada()

    Uso:
        Cuando una fila se hace update o se inserta en una tabla que contenga las columnas 
        de latitud y longitud se ejecuta automaticamente este trigger. Se setea la columna 
        'coordenada' creando un punto con los valores de 'longitud' y 'latitud'. 
        El punto se asigna el SRID 4326.

    Parámetros: 
        Ninguna.

    Retorno: 
        La función trigger retorna la nueva fila con la coordenada seteada.
*/
CREATE OR REPLACE FUNCTION set_coordenada()
RETURNS TRIGGER AS $$
BEGIN
    New.coordenada = ST_SetSRID(ST_MakePoint(New.longitud, New.latitud), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        set_latitud_longitud_origen()

    Uso:
        Cuando una fila se inserta o se hace update en la tabla 'preferencias' se ejecuta 
        automaticamente este trigger. Se setea la columna 'coordenada_origen' creando un 
        punto con los valores de 'longitud_origen' y 'latitud_origen'. 
        El punto se asigna el SRID 4326. Si los valores de 'longitud_origen' y 'latitud_origen'
        son nulos (esto ocurre cuando se inserta una nueva fila), se setean con los valores de 
        'longitud' y 'latitud' de la tabla 'perfil' que tenga el mismo 'id_cuenta' que la fila 
        insertada en 'preferencias'.

    Parámetros: 
        Ninguna.

    Retorna: 
        La función trigger retorna la nueva fila con la coordenada de origen insertada en la 
        tabla 'preferencias'.
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

/***********************************************************************************************************/
/*    
    Función:
        check_match_exists

    Uso:
        Chequear si dos personas dieron like el uno al otro.

    Parámetros:
        Ninguno.

    Retorno: 
        Función trigger que crea un match y un chat entre dos usuarios que dieron likes el 
        uno al otro.
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

/***********************************************************************************************************/
/*    
    Función:
        check_count_likes_or_superlikes()

    Uso:
        Verificar si un usuario ha dado mas de 100 likes al dia y no tiene el permiso
        de likes ilimitados.
        Ademas, verificar si un usuario ha dado mas de 1 superlike al dia y no tiene el permiso
        de 10 superlikes al dia, o verificar que tiene el permiso pero ya ha dado 10 superlikes al dia

    Parámetros:
        Ninguno.

    Retorna: 
        Función trigger que no permite dar mas de 100 likes al dia o 1 superlike al dia o 10 superlikes al dia
*/
CREATE OR REPLACE FUNCTION check_count_likes_or_superlikes()
RETURNS TRIGGER AS $$
BEGIN
    /* verificar si la nueva fila tiene super = True */
    IF NEW.super = TRUE THEN
        /* verificar si el usuario ha dado mas de 1 superlike al dia y no tiene el permiso de 10 superlikes al dia */
        IF (get_super_likes_per_day(New.id_liker, CURRENT_DATE)) = 1 THEN
            IF (check_if_user_has_a_permission(New.id_liker, '10super_likes_diario')) = FALSE THEN
                RAISE EXCEPTION 'No puedes dar mas de 1 superlike al dia';
            END IF;
        END IF;
        /* verificar si el usuario ha dado mas de 10 superlikes al dia */
        IF (get_super_likes_per_day(New.id_liker, CURRENT_DATE)) = 10 THEN
            RAISE EXCEPTION 'No puedes dar mas de 10 superlikes al dia';
        END IF;
    ELSIF (get_likes_per_day(New.id_liker, CURRENT_DATE)) = 100 THEN
        IF (check_if_user_has_a_permission(New.id_liker, 'likes_ilimitados')) = FALSE THEN
            RAISE EXCEPTION 'No puedes dar mas de 100 likes al dia';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_institution

    Uso: 
        Insertar una institucion a la base de datos.

    Parámetros:
        - i_dominio       : Dominio de la institucion.
        - i_nombre        : Nombre de la institucion.
        - i_tipo          : Tipo de la institucion.
        - i_ano_fundacion : Año de fundacion de la institucion.
        - i_latitud       : Latitud de la institucion.
        - i_longitud      : Longitud de la institucion.

    Retorno: 
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_institution(
    i_dominio       TEXT,
    i_nombre        TEXT,
    i_tipo          TEXT,
    i_ano_fundacion INTEGER,
    i_latitud       DECIMAL,
    i_longitud      DECIMAL) 
RETURNS VOID AS $$
BEGIN
    INSERT INTO institucion VALUES (i_dominio, i_nombre, i_tipo, i_ano_fundacion, i_latitud, i_longitud);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función: 
        get_all_Institutions()

    Uso:
        Retorna una tabla con los dominios y nombres de todas las instituciones registradas en 
        la base de datos para que el usuario pueda seleccionar una de ellas al momento de 
        registrarse.
    
    Parámetros: 
        Ninguna.
    
    Retorna: 
        Tabla con los dominios y nombres de todas las instituciones.
*/
CREATE OR REPLACE FUNCTION get_all_Institutions()
RETURNS TABLE (dominio VARCHAR, nombre VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT dominio, nombre FROM institucion;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/* 
    Función:
        insert_foto()

    Uso:
        Inserta un nuevo registro en la tabla tiene_foto.

    Parámetros:
        - p_user_id : Entero del id de la cuenta.
        - p_foto    : TEXT de la foto en formato base64.

    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_foto(p_user_id INTEGER, p_foto TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_foto (id_cuenta, foto) VALUES (p_user_id, decode(p_foto, 'base64'));
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función: 
        create_new_user()

    Uso: 
        Crea un nuevo usuario en la base de datos con la información proporcionada.

    Parámetros:
        - nombre_u            : Nombre del usuario.
        - apellido_u          : Apellido del usuario.
        - fecha_nacimiento_u  : Fecha de nacimiento del usuario.
        - telefono_u          : Número de teléfono del usuario.
        - email_u             : Correo electrónico del usuario.
        - password_hash       : Hash de la contraseña del usuario.
        - idioma_u            : Idioma preferido del usuario.
        - notificaciones_u    : Valor booleano que indica si el usuario desea recibir notificaciones.
        - tema_u              : Valor booleano que indica el tema preferido del usuario.
        - sexo_u              : Sexo del usuario.
        - latitud_u           : Valor decimal que representa la latitud de la ubicación del usuario.
        - longitud_u          : Valor decimal que representa la longitud de la ubicación del usuario.
        - foto_u              : Arreglo de textos en formato base64 que representa las fotos del usuario.
        - dominio_institucion : Dominio de la institución a la que estudio el usuario.
        - grado_u             : Grado académico en el titulo del usuario.
        - especialidad_u      : Especialidad en el titulo del usuario.
        - anio_ingreso        : Valor entero que representa el año de ingreso a la institución.
        - anio_egreso         : Valor entero que representa el año de egreso de la institución.

    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION create_new_user(
    nombre_u            TEXT, 
    apellido_u          TEXT, 
    fecha_nacimiento_u  DATE, 
    telefono_u          TEXT,
    email_u             TEXT, 
    password_hash       TEXT, 
    idioma_u            TEXT, 
    notificaciones_u    BOOLEAN, 
    tema_u              BOOLEAN, 
    sexo_u              TEXT, 
    latitud_u           DECIMAL(10, 8), 
    longitud_u          DECIMAL(11,8), 
    foto_u              TEXT[], 
    dominio_institucion TEXT, 
    grado_u             TEXT, 
    especialidad_u      TEXT, 
    anio_ingreso        INTEGER, 
    anio_egreso         INTEGER
) RETURNS VOID AS $$
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

    INSERT INTO cuenta (nombre, apellido, fecha_nacimiento, telefono, email, contrasena, idioma, notificaciones, tema) 
    VALUES (nombre_u, apellido_u, fecha_nacimiento_u, telefono_u, email_u, password_hash, idioma_u, notificaciones_u, tema_u) 
    RETURNING id_cuenta INTO id_cuenta_u;

    INSERT INTO perfil (id_cuenta, sexo, latitud, longitud) 
    VALUES (id_cuenta_u, sexo_u, latitud_u, longitud_u);

    INSERT INTO estudio_en(id_cuenta, dominio, grado, especialidad, ano_ingreso, ano_egreso) 
    VALUES (id_cuenta_u, dominio_institucion, grado_u, especialidad_u, anio_ingreso, anio_egreso);

    FOR i IN 1..array_length(foto_u, 1) LOOP
	PERFORM insert_foto(id_cuenta_u, foto_u[i]);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        get_email_and_hashpassword_user()

    Uso:
        Obtener el correo y el hash de la contrasena del usuario (para logins y cambios de contrasenas).

    Parámetros:
        - id_user: Valor entero del id del usuario.

    Retorna:
        El email y el hash de la contrasena del usuario.
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

/***********************************************************************************************************/
/*
    Función: 
        get_settings_app_user()

    Uso: 
        Obtener el idioma, notificaciones y tema del app que tiene un usuario.

    Parámetros:
        - id_user: Entero del id de la cuenta.

    Retorna:
        Una tabla con el idioma, notificaciones y tema del app que tiene un usuario.
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

/***********************************************************************************************************/
/*
    Función:  
        update_info_account()

    Uso: 
        Actualiza la informacion de la cuenta de un usuario en la tabla de cuenta. 
        Recordar que el usuario no puede cambiar su nombre ni apellido.

    Parámetros:
        - c_id_cuenta      : Valor entero del ID de la cuenta del usuario.
        - c_email          : (OPCIONAL) Texto con el nuevo email del usuario.
        - c_contrasena     : (OPCIONAL) Texto con el nuevo hash de contrasena del usuario.
        - c_telefono       : (OPCIONAL) Texto con el nuevo telefono del usuario.
        - c_idioma         : (OPCIONAL) Texto con el nuevo idioma del usuario.
        - c_tema           : (OPCIONAL) Texto con el nuevo tema del usuario.
        - c_notificaciones : (OPCIONAL) Valor booleano con el nuevo valor de notificaciones del usuario.

    Retorna: 
        Nada.
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

/***********************************************************************************************************/
/*
    Función: 
        update_info_perfil()

    Uso: 
        Actualiza la informacion de un perfil de un usuario.

    Parámetros:
        - p_id_cuenta: Valor entero del ID de la cuenta del usuario.
        - p_sexo: (OPCIONAL) TEXT del sexo de un usuario.
        - p_descripcion: (OPCIONAL) TEXT de la descripción de un usuario.
        - p_verificado: (OPCIONAL) BOOLEAN si el usuario esta verificado. Por default es false.
        - p_latitud: (OPCIONAL) DECIMAL de la latitud de un usuario.
        - p_longitud: (OPCIONAL) DECIMAL de la longitud de un usuario.

    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_info_perfil(
    p_id_cuenta   INTEGER,
    p_sexo        TEXT DEFAULT NULL,
    p_descripcion TEXT DEFAULT NULL,
    p_verificado  BOOLEAN DEFAULT FALSE,
    p_latitud     DECIMAL DEFAULT NULL,
    p_longitud    DECIMAL DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE perfil
    SET sexo        = CASE WHEN p_sexo        IS NOT NULL THEN p_sexo        ELSE sexo        END,
        descripcion = CASE WHEN p_descripcion IS NOT NULL THEN p_descripcion ELSE descripcion END,
        verificado  = CASE WHEN p_verificado  IS NOT FALSE THEN p_verificado ELSE verificado  END,
        latitud     = CASE WHEN p_latitud     IS NOT NULL THEN p_latitud     ELSE latitud     END,
        longitud    = CASE WHEN p_longitud    IS NOT NULL THEN p_longitud    ELSE longitud    END
    WHERE id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_preferences()

    Uso: 
        Insertar las preferencias de un usuario en la tabla de preferencias.

    Parámetros:
        - p_id_cuenta        : Valor entero del ID de la cuenta del usuario.
        - p_estudio          : (Opcional) TEXT del nivel de estudio del usuario.
        - p_latitud_origen   : (Opcional) DECIMAL de la latitud de preferencia del usuario.
        - p_longitud_origen  : (Opcional) DECIMAL de la longitud de preferencia del usuario.
        - p_distancia_maxima : (Opcional) Valor entero de la distancia máxima de búsqueda del usuario.
        - p_min_edad         : (Opcional) Valor entero de la edad mínima de búsqueda del usuario.
        - p_max_edad         : (Opcional) Valor entero de la edad máxima de búsqueda del usuario.

    Retorna: 
        Nada.
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

/***********************************************************************************************************/
/*
    Función: 
        update_preferences()

    Uso: 
        Actualiza las preferencias de un usuario en la tabla de preferencias.

    Parámetros:
        - p_id_cuenta        : Valor entero del ID de la cuenta del usuario.
        - p_estudio          : (Opcional) TEXT del nivel de estudio del usuario.
        - p_latitud_origen   : (Opcional) DECIMAL de la latitud de preferencia del usuario.
        - p_longitud_origen  : (Opcional) DECIMAL de la longitud de preferencia del usuario.
        - p_distancia_maxima : (Opcional) Valor entero de la distancia máxima de búsqueda del usuario.
        - p_min_edad         : (Opcional) Valor entero de la edad mínima de búsqueda del usuario.
        - p_max_edad         : (Opcional) Valor entero de la edad máxima de búsqueda del usuario.

    Retorna: 
        Nada.
*/
-- Ejemplo de uso SELECT update_preferences(p_id_cuenta := 19, p_estudio := 'Doctorado', p_distancia_maxima := 50);
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
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función: 
        get_preferences()

    Uso: 
        Obtener las preferencias de un usuario.

    Parámetros: 
        - p_id_cuenta : Valor entero del ID de la cuenta del usuario.

    Retorna: 
        Todos los datos de preferencias de un usuario.
*/
CREATE OR REPLACE FUNCTION get_preferences(p_id_cuenta integer)
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

/***********************************************************************************************************/
/*
    Función:
        get_users_by_estudio()

    Uso:
        Obtener usuarios por preferencias en estudio.

    Parámetros:
        - estudio : TEXT de estudio.

    Retorna: 
        Una tabla con los usuarios que cumplen con el estudio especificado.
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

/***********************************************************************************************************/
/*
    Función:
        get_users_by_genre()

    Uso:
        Obtener usuarios por preferencias en generos.

    Parámetros:
        - genre : Arreglo de TEXT de generos.

    Retorna:
        Una tabla con los usuarios que cumplen con alguno de los generos especificados.
*/
CREATE OR REPLACE FUNCTION get_users_by_genre(genre TEXT[])
RETURNS TABLE (r_id_cuenta INTEGER) AS $$
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

/***********************************************************************************************************/
/*
    Función:
        get_users_by_min_age()

    Uso:
        Obtener usuarios por preferencias en min edad.

    Parámetros: 
        - min_age: Entero de la edad minima.

    Retorna:
        Una tabla con los usuarios que cumplen con el min edad.
*/
CREATE OR REPLACE FUNCTION get_users_by_min_age(min_age INTEGER)
RETURNS TABLE (r_id_cuenta INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT id_cuenta
    FROM   cuenta
    WHERE  (EXTRACT(YEAR FROM AGE(fecha_nacimiento)) >= min_age);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        get_users_by_max_age()

    Uso:
        Obtener usuarios por preferencias en max edad.

    Parámetros:
        - max_age: Entero de la edad maxima.

    Retorna:
        Una tabla con los usuarios que cumplen con el max edad.
*/
CREATE OR REPLACE FUNCTION get_users_by_max_age(max_age INTEGER)
RETURNS TABLE (r_id_cuenta INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT id_cuenta
    FROM   cuenta
    WHERE  (EXTRACT(YEAR FROM AGE(fecha_nacimiento)) <= max_age);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        get_users_by_orientation_sexual()

    Uso:
        Obtener los usuarios por preferencias de un arreglo de TEXT de orientaciones sexuales.

    Parámetros:
        - orientation_sexual : Arreglo de TEXT con las orientaciones sexuales.

    Retorna:
        Tabla con los IDs de usuarios que tienen alguna de las orientaciones sexuales especificadas.
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

/***********************************************************************************************************/
/*
    Función:
        get_all_users_by_max_distance()

    Uso:
        Obtener todos los IDs de los usuarios que se encuentren a una distancia máxima de un usuario 
        dado (no se considera en el resultado el usuario dado).

    Parámetros:
        - user_id : Valor entero del Id de la cuenta del usuario a partir del cual se calculará la distancia.

    Retorno:
        Una tabla con los IDs de los usuarios que se encuentren a una distancia máxima de un usuario dado.
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

/***********************************************************************************************************/
/*
    Función:
        get_users_by_preferences_free_user()

    Uso:
        Obtener los ids cuentas de los usuarios que cumplen con las preferencias de otro usuario que 
        no tiene suscripcion con passport.

    Parámetros:
        - user_id : id del usuario que tiene las preferencias.

    Retorna:
        Tabla con los ids de las cuentas de los usuarios que cumplen con las preferencias.
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

/***********************************************************************************************************/
/*
    Función:
        insert_pref_sexo()

    Uso:
        Inserta una nueva preferencia de sexo para un usuario en la tabla de pref_sexo.
 
    Parámetros: 
        - p_id_cuenta : Valor entero del ID de la cuenta del usuario.
        - p_sexo      : Texto que indica el nuevo sexo de preferencia del usuario.
 
    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_pref_sexo(p_id_cuenta INTEGER, p_sexo TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO pref_sexo(id_cuenta, sexo) VALUES (p_id_cuenta, p_sexo);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_pref_sexo()

    Uso:
        Elimina una preferencia de sexo de un usuario en la tabla de pref_sexo.

    Parámetros:
        - p_id_cuenta : Valor entero del ID de la cuenta del usuario.
        - p_sexo      : Texto que indica el sexo a eliminar de las preferencias del usuario.

    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_pref_sexo(p_id_cuenta INTEGER, p_sexo TEXT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM pref_sexo WHERE id_cuenta = p_id_cuenta AND sexo = p_sexo;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_pref_orientacion_sexual()

    Uso:
        Inserta una nueva preferencia de orientacion sexual para un usuario en la tabla de pref_orientacion_sexual.

    Parámetros:
        - p_id_cuenta          : Valor entero del ID de la cuenta del usuario.
        - p_orientacion_sexual : Texto que indica la nueva orientacion sexual de preferencia del usuario.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_pref_orientacion_sexual(p_id_cuenta INTEGER, p_orientacion_sexual TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO pref_orientacion_sexual(id_cuenta, orientacion_sexual) 
    VALUES (p_id_cuenta, p_orientacion_sexual);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_pref_orientacion_sexual()

    Uso:
        Elimina una preferencia de orientacion sexual de un usuario en la tabla de pref_orientacion_sexual.

    Parámetros:
        - p_id_cuenta          : Valor entero del ID de la cuenta del usuario.
        - p_orientacion_sexual : Texto que indica la orientacion sexual a eliminar de las preferencias del usuario.

    Retorno:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_pref_orientacion_sexual(p_id_cuenta INTEGER, p_orientacion_sexual TEXT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM pref_orientacion_sexual 
    WHERE id_cuenta = p_id_cuenta AND orientacion_sexual = p_orientacion_sexual;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_user_tarjeta()

    Uso:
        Cuando el usuario registra una tarjeta, se inserta una instancia en la tabla tarjeta 
        (si es que aun no existen en la base de datos), y se asocia a la cuenta del usuario 
        creando una instancia en la tabla registra.
 
    Parámetros:
        - user_id     : Valor entero que indica el id del usuario.
        - card_number : TEXT numero de la tarjeta.
        - titular     : TEXT nombre del titular de la tarjeta.
        - due_date    : DATE fecha de vencimiento de la tarjeta.
        - cvv         : TEXT codigo de seguridad de la tarjeta.
        - type_card   : TEXT tipo de tarjeta.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_user_tarjeta(
    user_id     INT, 
    card_number TEXT, 
    titular     TEXT, 
    due_date    DATE, 
    cvv         TEXT, 
    type_card   TEXT
) RETURNS VOID AS $$
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

/***********************************************************************************************************/
/*
    Función:
        delete_instance_registra()

    Uso:
        Elimina una instancia de la tabla registra.

    Parámetros:
        - user_id     : Valor entero que indica el id del usuario.
        - card_number : TEXT numero de la tarjeta.

    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION delete_instance_registra(user_id INTEGER, card_number TEXT) 
RETURNS VOID AS $$
BEGIN
    DELETE FROM registra WHERE id_cuenta = user_id AND digitos_tarjeta = card_number;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        update_due_date_card()

    Uso:
        Actualizar la fecha de vencimiento de una tarjeta.

    Parámetros: 
        - card_number  : TEXT indica los numeros de la tarjeta a modificar fecha de caducidad.
        - new_due_date : DATE indica la nueva fecha de vencimiento de la tarjeta.

    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION update_due_date_card(card_number TEXT, new_due_date DATE)
RETURNS VOID AS $$
BEGIN
    UPDATE tarjeta
    SET    fecha_caducidad = new_due_date
    WHERE  digitos_tarjeta = card_number;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        get_all_public_info_about_user()

    Uso:
        Obtener todos los datos que sean considerados como publico de un usuario con su 
        id_cuenta (nombre, apellido, edad, sexo, descripcion, verificado, latitud y 
        longitud para mostrar la ciudad y pais con Nominatim, dominios de las instituciones 
        en que estudio, Ids de la empresa que trabaja, hobbies, habilidades, certificaciones, 
        fotos, orientaciones sexuales) para mostrarse en el perfil.

    Parámetros:
        - id_user : id de la cuenta del usuario.

    Retorno:
        Devuelve una tabla de una fila con todos los datos (mencionados en el Uso) del usuario 
        con el id_cuenta.
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

/***********************************************************************************************************/
/*
    Función:
        insert_trabaja_en()

    Uso:
        Cuando el usuario quiere agregar en que empresa trabaja actualmente, se inserta una 
        nueva instancia de empresa (si es que no existe en la bd) y se inserta una nueva 
        instancia de trabaja_en.

    Parámetros: 
        - id_user          : Entero del id de la cuenta del usuario.
        - e_nombre_empresa : TEXT con el nombre de la empresa.
        - e_url_empresa    : TEXT con el url de la empresa.
        - e_puesto         : TEXT con el cargo del usuario en la empresa.
        - e_fecha_inicio   : DATE con la fecha de inicio en que trabaja en la empresa.

    Retorno: 
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_trabaja_en(
    id_user          INT,
    e_nombre_empresa TEXT,
    e_url_empresa    TEXT,
    e_puesto         TEXT,
    e_fecha_inicio   DATE
) RETURNS VOID AS $$
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

/***********************************************************************************************************/
/*
    Función:
        insert_or_delete_agrupation()

    Uso:
        Insertar o eliminar una agrupacion de un usuario en una institucion en la tabla esta_en_agrupacion.

    Parámetros:
        - p_id_cuenta  : Entero del id de la cuenta de un usuario.
        - p_id_dominio : TEXT dominio de una institucion.
        - p_agrupacion : TEXT de la agrupacion a insertar.
        - wanna_delete : BOOLEAN True si es delete, False si es insert. 

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_or_delete_agrupation(p_id_cuenta integer, p_id_dominio TEXT, p_agrupacion TEXT, wanna_delete BOOLEAN)
RETURNS VOID AS $$
BEGIN
    IF wanna_delete THEN
        DELETE FROM esta_en_agrupacion
        WHERE id_cuenta = p_id_cuenta AND dominio = p_id_dominio AND agrupacion = p_agrupacion;
    ELSE
        INSERT INTO esta_en_agrupacion(id_cuenta, dominio, agrupacion)
        VALUES (p_id_cuenta, p_id_dominio, p_agrupacion);
    END IF;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/* 
    Función:
        get_all_info_about_a_user_trabaja_en()

    Uso:
        Obtener todos los datos de trabaja_en (cargo y fechas de inicio) de un usuario en una empresa.

    Parámetros: 
        - p_id_cuenta  : Entero del id de la cuenta de un usuario.
        - p_id_empresa : Entero del id de la empresa en que trabaja.

    Retorna: 
        Una tabla de una fila con los datos de trabaja_en asociados a la id_cuenta = p_id_cuenta 
        e id_empresa = p_id_empresa.
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

/***********************************************************************************************************/
/*
    Función:
        get_all_info_about_a_empresa()

    Uso:
        Obtener toda la informacion de una empresa (url y nombre).

    Parámetros:
        - idEmpresa: Entero del id de la empresa.

    Retorna:
        Tabla de una fila con el nombre y url de la empresa.
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

/***********************************************************************************************************/
/* 
    Función:
        update_visto_msj()

    Uso:
        Actualizar el true del visto de un mensaje en la tabla mensaje.

    Parámetros: 
        - p_id_chat     : entero que representa el id del chat.
        - p_nro_mensaje : entero que representa el nro del mensaje en el chat.

    Retorna: 
        Nada.
*/
CREATE OR REPLACE FUNCTION update_visto_msj(p_id_chat integer, p_nro_mensaje integer) 
RETURNS VOID AS $$
BEGIN
    UPDATE mensaje
    SET    visto = TRUE
    WHERE  id_chat = p_id_chat AND numero_msj = p_nro_mensaje;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_hobbies()

    Uso:
        Inserta un nuevo registro en la tabla tiene_hobby.

    Parámetros:
        - p_user_id : Entero del id de la cuenta.
        - p_hobby   : TEXT del hobby.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_hobbies(p_user_id INTEGER, p_hobby TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_hobby (id_cuenta, hobby)
    VALUES (p_user_id, p_hobby);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/* 
    Función:
        insert_habilidades()

    Uso:
        Inserta un nuevo registro en la tabla tiene_habilidades.

    Parámetros:
        - p_user_id   : Entero del id de la cuenta.
        - p_habilidad : TEXT del habilidad.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_habilidades(p_user_id INTEGER, p_habilidad TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_habilidades (id_cuenta, habilidad)
    VALUES (p_user_id, p_habilidad);
END;
$$ LANGUAGE plpgsql;


/***********************************************************************************************************/
/*
    Función:
        insert_certificacion()

    Uso:
        Inserta un nuevo registro en la tabla tiene_certificaciones.

    Parámetros:
        - p_user_id       : Entero del id de la cuenta.
        - p_certificacion : TEXT de la certificacion.

    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_certificacion(p_user_id INTEGER, p_certificacion TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_certificaciones (id_cuenta, certificaciones) VALUES (p_user_id, p_certificacion);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_orientacion_sexual_perfil()

    Uso:
        Inserta un nuevo registro en la tabla tiene_orientacion_sexual.

    Parámetros:
        - p_user_id            : Entero del id de la cuenta.
        - p_orientacion_sexual : TEXT de la orientacion sexual.

    Retorna: Nada.
*/
CREATE OR REPLACE FUNCTION insert_orientacion_sexual_perfil(p_user_id INTEGER, p_orientacion_sexual TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_orientacion_sexual (id_cuenta, orientacion_sexual)
    VALUES (p_user_id, p_orientacion_sexual);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/* 
    Función:
        delete_hobby()

    Uso:
        Eliminar una instancia en tiene_hobby dado el id_cuenta de un usuario.

    Parámetros:
        - p_user_id : Entero del id de la cuenta.
        - p_hobby   : TEXT del hobby.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_hobby(p_user_id INTEGER, p_hobby TEXT) 
RETURNS VOID AS $$
BEGIN
    DELETE FROM tiene_hobby
    WHERE id_cuenta = p_user_id AND hobby = p_hobby;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_habilidad()

    Uso:
        Eliminar una instancia en tiene_habilidades dado el id_cuenta de un usuario.

    Parámetros:
        - p_user_id   : Entero del id de la cuenta.
        - p_habilidad : TEXT de la habilidad.

    Retorna:
        Nada
*/
CREATE OR REPLACE FUNCTION delete_habilidad(p_user_id INTEGER, p_habilidad TEXT) RETURNS VOID AS $$
BEGIN
    DELETE FROM tiene_habilidades
    WHERE id_cuenta = p_user_id AND habilidad = p_habilidad;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_foto()

    Uso:
        Eliminar una instancia en tiene_foto dado el id_cuenta de un usuario, pero si es la unica 
        foto que queda no se elimina.

    Parámetros:
        - p_user_id : Entero del id de la cuenta.
        - p_id_foto : Entero del id de la foto a eliminar.

    Retorna:
        Nada.
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
        RAISE EXCEPTION 'No se puede eliminar la unica foto.';
    END IF;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_certificacion()

    Uso:
        Eliminar una instancia en tiene_certificacion dado el id_cuenta de un usuario.

    Parámetros:
        - p_user_id       : Entero del id de la cuenta.
        - p_certificacion : TEXT de la certificacion.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_certificacion(p_user_id INTEGER, p_certificacion TEXT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM tiene_certificaciones
    WHERE id_cuenta = p_user_id AND certificaciones = p_certificacion;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_orientacion_sexual_perfil()

    Uso:
        Eliminar una instancia en tiene_orientacion_sexual dado el id_cuenta de un usuario.

    Parámetros:
        - p_user_id            : Entero del id de la cuenta.
        - p_orientacion_sexual : TEXT de la orientacion sexual.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_orientacion_sexual_perfil(p_user_id INTEGER, p_orientacion_sexual TEXT) 
RETURNS VOID AS $$
BEGIN
    DELETE FROM tiene_orientacion_sexual
    WHERE id_cuenta = p_user_id AND orientacion_sexual = p_orientacion_sexual;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        update_institution()

    Uso:
        Modificar el nombre, tipo o año de fundacion de una institucion.

    Parámetros:
        - p_dominio       : TEXT dominio de la institucion a modificar.
        - p_nombre        : (OPCIONAL) TEXT nombre de la institucion.
        - p_tipo          : (OPCIONAL) TEXT tipo de la institucion.
        - p_ano_fundacion : (OPCIONAL) entero del año de fundacion de la institucion 
                            (por si se equivoco al principio colocarlo).

    Retorna:
        Nada.
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

/***********************************************************************************************************/
/*
    Función:
        get_data_pago()

    Uso:
        Obtener todos los datos de un pago.

    Parámetros: 
        - p_id_pago : Entero ID del pago.

    Retorno:
        Devuelve un registro con todos los datos del pago.
*/
CREATE OR REPLACE FUNCTION get_data_pago(p_id_pago integer)
RETURNS TABLE(
    r_id_pago           INTEGER,
    r_numero_factura    INTEGER,
    r_estado            BOOLEAN,
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
        monto,
        fecha,
        encode(documento_factura, 'base64')
    FROM pago
    WHERE id_pago = p_id_pago;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        check_if_user_has_a_permission()

    Uso:
        Verificar si un usuario tiene un permiso en particular.

    Parámetros:
        - user_id         : Valor entero del Id de la cuenta del usuario.
        - permission_name : Valor texto del nombre del permiso que se desea verificar.

    Retorno: 
        Retorna un valor booleano que indica si el usuario tiene el permiso o no.
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
                    AND fecha_inicio + (plazo || ' months')::INTERVAL > CURRENT_DATE
                )
    ) INTO permission_exists;

    RETURN permission_exists;
END;
$$ LANGUAGE plpgsql;


/***********************************************************************************************************/
/*
    Función: 
        get_all_users_by_10km_radius()

    Uso: 
        Obtener todos los IDs de los usuarios que se encuentren alrededor de 10 km de una 
        coordenada de origen dada.

    Parámetros:
        - user_id : Valor entero del Id de la cuenta del usuario que desea encontrar a las 
                    otras personas por su coordenada origen de preferencias.

    Retorno: 
        Retorna una tabla con los IDs de los usuarios que se encuentren en esa coordenada 
        de origen dada y dentro de 10 km de radio.
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

/***********************************************************************************************************/
/*
    Función:
        get_users_by_preferences_passport_user()

    Uso: 
        Obtener los ids cuentas de los usuarios que se encuentra en una ciudad 
        (por coordenada origen en preferencias) y que cumplen con las preferencias 
        de estudio, min y max edad, sexos y orientaciones sexuales de otro usuario.

    Parámetros:
        - user_id : id del usuario que tiene las preferencias y con permiso passport.

    Retorno: 
        Tabla con los ids de las cuentas de los usuarios que cumplen con las preferencias.
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
        AND id_cuenta IN (SELECT r_id_cuenta FROM get_all_users_by_10km_radius(user_id));
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        get_chats_by_user()

    Uso:
        Obtener los ids chats que participa un usuario.

    Parámetros:
        - user_id : Id del usuario.

    Retorno:
        Tabla con los ids de los chats.
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

/***********************************************************************************************************/
/*
    Función:
        insert_like()

    Uso:
        Para agregar un nuevo like a la tabla de likes.

    Parámetros: 
        - liker     : Id de quien da like.
        - liked     : Id de quien recibe el like.
        - superlike : True si fue un superlike, false en caso contrario.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_like(liker INT, liked INT, superlike BOOL DEFAULT FALSE) 
RETURNS VOID AS $$
BEGIN
	INSERT INTO likes(id_liker, id_liked, super) VALUES (liker, liked, superlike);
END; 
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_swipe()

    Uso:
        Para agregar un nuevo dislike a la tabla de swipes.

    Parámetros: 
        - disliker : Id de quien da dislike.
        - disliked : Id de quien recibe el dislike.

    Retorna: 
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_swipe(disliker INT, disliked INT)
	RETURNS VOID AS $$
BEGIN
	INSERT INTO swipes(id_disliker, id_disliked) VALUES (disliker, disliked);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función: 
        delete_like()

    Uso: 
        Para que un usuario elimine un like que dio anteriormente
        con la condicion de que dicho usuario debe estar suscrito a un tier.

    Parámetros: 
        - id_user : Id de quien elimina el like.
        - liked   : Id de quien se borra el like.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_like(id_user INT, liked INT)
RETURNS VOID AS $$
BEGIN
    IF (check_if_user_has_a_permission(id_user, 'rewinds_ilimitados')) THEN 
        DELETE FROM likes WHERE id_liker = id_user AND id_liked = liked;
    ELSE
        RAISE EXCEPTION 'El usuario no tiene permiso para realizar esta acción.';
    END IF;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_match()

    Uso:
        Agregar un match en caso de que dos usuarios se den like mutuamente 
        y crear un chat entre ambos.

    Parámetros: 
        - id_user1 : Id de uno de los dos usuarios del match.
        - id_user2 : Id de uno de los dos usuarios del match.

    Retorna:
        Nada.
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

/***********************************************************************************************************/
/*
    Función:
        price_of_tier
    
    Uso:
        Obtiene el precio de un tier.
    
    Parámetros:
        - nombre_t : Nombre del tier.

    Retorno:
        Precio del tier en formato DECIMAL(10, 2).
*/
CREATE OR REPLACE FUNCTION price_of_tier(nombre_t TEXT)
RETURNS DECIMAL(10, 2) AS $$
BEGIN
    RETURN (SELECT monto_tier FROM tier WHERE nombre_tier = nombre_t);
END;
$$ LANGUAGE plpgsql;


/***********************************************************************************************************/
/*
    Función:
        subscribe_user()

    Uso:
        Realiza la suscripción de un usuario a un tier y gestiona el proceso de pago.

    Parámetros: 
        - id_cuenta_usuario         : ID de la cuenta del usuario que desea suscribirse.
        - nombre_tier_usuario       : Nombre del tier al que desea suscribirse el usuario.
        - plazo_tier                : Plazo en meses de la suscripción.
        - digitos_tarjeta_usario    : Dígitos de la tarjeta de crédito del usuario para el pago.
        - numero_factura_actual     : Número de factura del pago.
        - estado_pago               : Estado del pago (TRUE si está aprobado, FALSE si está pendiente o rechazado).
        - monto_pago                : Monto del pago realizado.
        - documento_factura_usuario : Documento de la factura en formato base64.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION subscribe_user(
    id_cuenta_usuario         INT,
    nombre_tier_usuario       TEXT,
    plazo_tier                INT,
    digitos_tarjeta_usario    TEXT,
    numero_factura_actual     INT,
    estado_pago               BOOLEAN,
    monto_pago                DECIMAL(10,2),
    documento_factura_usuario TEXT
) RETURNS VOID AS $$
DECLARE
    new_id_pago INT;
BEGIN
    -- Verificar el estado del pago.
    IF NOT estado_pago THEN
        RAISE EXCEPTION 'El pago debe estar aprobado para poder suscribirse al tier.';
    END IF;

    -- Verificar si la cuenta y la tarjeta existen y si el tier está disponible
    IF NOT EXISTS (SELECT 1 FROM cuenta WHERE id_cuenta = id_cuenta_usuario) THEN
        RAISE EXCEPTION 'La cuenta con id % no existe', id_cuenta_usuario;
    END IF;

    -- Verificar que la tarjeta existe.
    IF NOT EXISTS (SELECT 1 FROM tarjeta WHERE digitos_tarjeta = digitos_tarjeta_usario) THEN
        RAISE EXCEPTION 'La tarjeta con dígitos % no existe', digitos_tarjeta_usario;
    END IF;

    -- Verificar que la tarjeta no esté vencida.
    IF check_due_card(digitos_tarjeta_usario) THEN
        RAISE EXCEPTION 'La tarjeta con dígitos % está vencida.', digitos_tarjeta_usario;
    END IF;

    -- Verificar que la tarjeta sea una registrada por el usuario.
    IF NOT EXISTS (SELECT 1 FROM registra WHERE id_cuenta = id_cuenta_usuario AND digitos_tarjeta = digitos_tarjeta_usario) THEN
        RAISE EXCEPTION 'La tarjeta con dígitos % no está registrada por el usuario %.', digitos_tarjeta_usario, id_cuenta_usuario;
    END IF;

    -- Verificar que el tier exista.
    IF NOT EXISTS (SELECT 1 FROM tier WHERE nombre_tier = nombre_tier_usuario) THEN
        RAISE EXCEPTION 'El tier % no existe', nombre_tier_usuario;
    END IF;

    -- Verificar valor correcto de plazos.
    IF NOT plazo_tier IN (1, 3, 6, 12) THEN
        RAISE EXCEPTION 'El plazo debe ser 1, 3, 6 o 12 meses';
    END IF;

    -- Verificar si el usuario ya está suscrito a un tier activo
    IF EXISTS (
        SELECT 1 
        FROM   suscrita
        WHERE  id_cuenta = id_cuenta_usuario
                AND  fecha_inicio + (plazo_tier || ' months')::INTERVAL > CURRENT_DATE
    ) THEN
        RAISE EXCEPTION 'El usuario ya está suscrito a un tier activo.';
    END IF;

    -- Verificar el monto con la subscripción a relacionar.
    IF NOT monto_pago = price_of_tier(nombre_tier_usuario)*plazo_tier THEN
        RAISE EXCEPTION 'El monto del pago no coincide con el monto del tier.';
    END IF;

    -- INSERCION DE DATOS
    -- Insertar el pago.
    INSERT INTO pago (numero_factura, estado, monto, documento_factura)
    VALUES (numero_factura_actual, estado_pago, monto_pago, decode(documento_factura_usuario, 'base64'))
    RETURNING id_pago INTO new_id_pago;

    -- Insertar la realizacion del pago.
    INSERT INTO realiza (id_cuenta, id_pago, digitos_tarjeta)
    VALUES (id_cuenta_usuario, new_id_pago, digitos_tarjeta_usario);

    -- Insertar la subscripcion del usuario al tier.
    INSERT INTO suscrita (id_cuenta, nombre_tier, fecha_inicio, plazo)
    VALUES (id_cuenta_usuario, nombre_tier_usuario, CURRENT_DATE, plazo_tier);
    
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        cancel_match()

    Uso:
        Eliminar el match entre dos usuarios, eliminando tambien el chat y los likes 
        que se hayan dado entre ellos. Ademas, ya al eliminar el chat se elimina los 
        mensajes y la instancia de chatea_con.

    Parámetros:
        - id_user_canceling : INT del usuario que cancela el match.
        - id_user_canceled  : INT del usuario que se cancela el match.

    Retorno:
        Nada.
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

/***********************************************************************************************************/
/*
    Función:
        get_number_of_likes()

    Uso:
        Calcular el numero de likes que ha recibido una persona.

    Parámetros: 
        - id_user : Id de uno del usuario.

    Retorna:
        Entero que representa el total de likes.
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

/***********************************************************************************************************/
/*
    Función:
        get_likes_per_day()

    Uso:
        Calcular el numero de likes que da un usuario al dia.

    Parámetros: 
        - id_user  : Id del usuario a calcular.
        - from_day : Fecha a buscar.

    Retorna:
        Entero que representa el numero de likes dados en un dia.
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

/***********************************************************************************************************/
/*
    Función:
        delete_cuenta()

    Uso:
        Elimina una cuenta.

    Parámetros:
        - p_id_cuenta : Valor entero del ID de la cuenta del usuario a eliminar.

    Retorna: 
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_cuenta(p_id_cuenta INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM cuenta WHERE id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        get_file()

    Uso:
        Obtener archivos.

    Parámetros: 
        - chat_id   : Id del chat correspondiente.
        - message   : Numero del mensaje correspondiente.
        - name_file : Nombre del archivo a obtener.

    Returno:
        Tabla con los datos del archivo.
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

/***********************************************************************************************************/
/*
    Función:
        set_null_estudio()

    Uso:
        Si el usuario ya no quiere buscar personas por su estudio, se setea null a este 
        atributo en la tabla preferencias.

    Parámetros: 
        - p_id_cuenta: id de la cuenta del usuario

    Returna:
        Nada.
*/
CREATE OR REPLACE FUNCTION set_null_estudio(p_id_cuenta integer)
RETURNS void AS $$
BEGIN
    UPDATE preferencias
    SET    estudio = NULL
    WHERE  id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        set_default_latitud_longitud_origen

    Uso:
        Si el usuario ya no quiere buscar personas por un punto de coordenada o se termina
        su suscripcion a un tier con permiso passport, se setea la coordenada origen al 
        valor defecto (que es la coordenada donde esta el usuario) en la tabla preferencias.

    Parámetros
        - p_id_cuenta: id de la cuenta del usuario.

    Returna: 
        Nada.
*/
CREATE OR REPLACE FUNCTION set_default_latitud_longitud_origen(p_id_cuenta integer)
RETURNS VOID AS $$
BEGIN
    -- Se setea null, ya que hay un trigger que setea por default a las coordenadas del usuario.
    UPDATE preferencias
    SET    latitud_origen = NULL, longitud_origen = NULL
    WHERE  id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_new_estudio_en()

    Uso:
        Insertar una nueva instancia en estudio_en y en esta_en_agrupacion.

    Parámetros:
        - id_user              : Id de la cuenta del usuario.
        - p_dominio            : Dominio de la institucion.
        - p_nombre_institucion : Nombre de la institucion.
        - p_grado              : Grado academico.
        - p_especialidad       : Especialidad.
        - p_ano_inicio         : Año de ingreso.
        - p_ano_fin            : Año de egreso.
        - p_agrupaciones       : OPCIONAL, Arreglo de nombre de agrupaciones.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_new_estudio_en(
    id_user        INTEGER,
    p_dominio      TEXT,
    p_grado        TEXT,
    p_especialidad TEXT,
    p_ano_inicio   INTEGER,
    p_ano_fin      INTEGER,
    p_agrupaciones TEXT[] DEFAULT NULL
) RETURNS void AS $$
DECLARE
    i INTEGER;
BEGIN
    INSERT INTO estudio_en
    VALUES (id_user, p_dominio, p_grado, p_especialidad, p_ano_inicio, p_ano_fin);

    IF p_agrupaciones IS NOT NULL THEN
        FOR i IN 1..array_length(p_agrupaciones, 1) LOOP
	    PERFORM insert_or_delete_agrupation(id_user, p_dominio, p_agrupaciones[i], FALSE);
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/* 
    Función:
        get_user_estudio_en()

    Uso:
        Obtener todos los datos (grados academicos con sus especialidades, años de ingreso y egreso) 
        de estudio_en dado por su dominio de institucion e id_cuenta.
        Las agrupaciones se obtienen con otra funcion.

    Parámetros: 
        - p_id_cuenta  : Entero del id de la cuenta de un usuario.
        - p_id_dominio : TEXT dominio de una institucion.

    Retorno:
        Una tabla con los datos de estudio_en asociados a la id_cuenta = p_id_cuenta 
        y dominio = p_id_dominio.
*/
CREATE OR REPLACE FUNCTION get_user_estudio_en(p_id_cuenta integer, p_id_dominio TEXT)
RETURNS TABLE(
    r_grado        estudios, 
    r_especialidad CHARACTER VARYING, 
    r_ano_ingreso  INTEGER, 
    r_ano_egreso   INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT grado, especialidad, ano_ingreso, ano_egreso
    FROM   estudio_en
    WHERE  id_cuenta = p_id_cuenta AND dominio = p_id_dominio;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        get_user_agrupaciones_in_a_institution()

    Uso:
        Obtener todas las agrupaciones de estudio_en de un usuario dado por su id_cuenta y dominio de la institucion

    Parámetros:
        - p_id_cuenta  : Entero del id de la cuenta de un usuario.
        - p_id_dominio : TEXT dominio de una institucion.

    Retorno:
        Una tabla de los nombres de las agrupaciones.
*/
CREATE OR REPLACE FUNCTION get_user_agrupaciones_in_a_institution(p_id_cuenta integer, p_id_dominio TEXT)
RETURNS TABLE(
    r_agrupacion CHARACTER VARYING
) AS $$
BEGIN
    RETURN QUERY
    SELECT agrupacion
    FROM   esta_en_agrupacion
    WHERE  id_cuenta = p_id_cuenta AND dominio = p_id_dominio;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_files()

    Uso:
        Crear instancias en la tabla archivo.
 
    Parámetros: 
        - chat_id      : Id del chat correspondiente.
        - name_file    : Arreglo de nombres de un archivo a guardar.
        - type_file    : Arreglo de tipos de un archivo a guardar.
        - content_file : Arreglo de contenido de un archivo a guardar en formato base64.
        - remitente_id : Id del remitente.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_files(
    chat_id      INT, 
    name_file    TEXT[], 
    type_file    TEXT[],
    content_file TEXT[],
    remitente_id INT
) RETURNS VOID AS $$
DECLARE 
	new_msg_num       INT;
    nro_name_files    INT;
    nro_type_files    INT;
    nro_content_files INT;
BEGIN
	INSERT INTO mensaje (id_chat, id_remitente) 
	VALUES (chat_id, remitente_id)
	RETURNING numero_msj INTO new_msg_num;

    nro_name_files    := array_length(name_file, 1);
    nro_type_files    := array_length(type_file, 1);
    nro_content_files := array_length(content_file, 1);

    IF nro_name_files != nro_type_files OR nro_name_files != nro_content_files THEN
        RAISE EXCEPTION 'Los arreglos de nombres, tipos y contenido de los archivos deben tener la misma longitud';
    END IF;

    FOR i IN 1..nro_name_files LOOP
        INSERT INTO archivo 
        VALUES (chat_id, new_msg_num, name_file[i], type_file[i], decode(content_file[i], 'base64'));
    END LOOP;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        verify_exist_tier()
    
    Uso:
        Verifica si existe un tier en el sistema.
    
    Parámetros:
        - nombre_t : Nombre del tier a verificar.

    Retorna:
        Bool. True si el tier existe, False si no.
*/
CREATE OR REPLACE FUNCTION verify_exist_tier(nombre_t TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM tier WHERE nombre_tier = nombre_t);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        verify_exist_permission()

    Uso:
        Verifica si existe un permiso en el sistema.
    
    Parámetros:
        - nombre_p : Nombre del permiso a verificar.

    Retorna:
        Bool. True si el permiso existe, False si no.
*/
CREATE OR REPLACE FUNCTION verify_exist_permission(nombre_p TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM permiso WHERE nombre_permiso = nombre_p);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_new_tier()

    Uso:
        Crear un nuevo tier en el sistema.

    Parámetros:
        - nombre_nuevo_tier : Nombre del nuevo tier.
        - monto_nuevo_tier  : Monto del nuevo tier.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_new_tier(nombre_nuevo_tier TEXT, monto_nuevo_tier DECIMAL(10,2))
RETURNS VOID AS $$
BEGIN
    IF verify_exist_tier(nombre_nuevo_tier) THEN
        RAISE EXCEPTION 'El tier % ya existe en el sistema.', nombre_nuevo_tier;
    END IF;

    INSERT INTO tier (nombre_tier, monto_tier)
    VALUES (nombre_nuevo_tier, monto_nuevo_tier);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        update_price_tier()
    
    Uso:
        Actualizar el monto de un tier en el sistema.
    
    Parámetros:
        - nombre_t : Nombre del tier a actualizar.
        - monto_t  : Monto del tier a actualizar.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION update_price_tier(nombre_t TEXT, monto_t DECIMAL(10,2))
RETURNS VOID AS $$
BEGIN
    IF NOT verify_exist_tier(nombre_t) THEN
        RAISE EXCEPTION 'El tier % no existe en el sistema.', nombre_t;
    END IF;

    UPDATE tier SET monto_tier = monto_t WHERE nombre_tier = nombre_t;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        insert_new_permission()

    Uso:
        Crear un nuevo permiso en el sistema.

    Parámetros:
        - nombre_nuevo_permiso : Nombre del nuevo permiso.
        - descripcion_nuevo_permiso : Descripción del nuevo permiso.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION insert_new_permission(nombre_nuevo_permiso TEXT, descripcion_nuevo_permiso TEXT)
RETURNS VOID AS $$
BEGIN
    IF verify_exist_permission(nombre_nuevo_permiso) THEN
        RAISE EXCEPTION 'El permiso % ya existe en el sistema.', nombre_nuevo_permiso;
    END IF;

    INSERT INTO permiso (nombre_permiso, descripcion_permiso)
    VALUES (nombre_nuevo_permiso, descripcion_nuevo_permiso);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        link_tiers_with_permissions()

    Uso:
        Vincular un tier con un permiso en la tabla maneja.

    Parámetros:
        - nombre_tier_t : Nombre del tier a vincular con el permiso.
        - nombre_per_p  : Nombre del permiso a vincular con el tier.
    
    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION link_tiers_with_permissions(nombre_tier_t TEXT, nombre_per_p TEXT)
RETURNS VOID AS $$
BEGIN
    IF NOT verify_exist_tier(nombre_tier_t) THEN
        RAISE EXCEPTION 'El tier % no existe en el sistema.', nombre_tier_t;
    END IF;

    IF NOT verify_exist_permission(nombre_per_p) THEN
        RAISE EXCEPTION 'El permiso % no existe en el sistema.', nombre_per_p;
    END IF;

    IF EXISTS (SELECT 1 FROM maneja WHERE nombre_tier = nombre_tier_t AND nombre_permiso = nombre_per_p) THEN
        RAISE EXCEPTION 'El tier % ya tiene el permiso %.', nombre_tier_t, nombre_per_p;
    END IF;

    INSERT INTO maneja (nombre_tier, nombre_permiso)
    VALUES (nombre_tier_t, nombre_per_p);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_tier()
    
    Uso:
        Eliminar un tier del sistema. Este tier debe no estar relacionado con ningun subcripcion, es decir
        si existe al menos un usuario subscrito al tier a eliminar entonces se deniega la operación.
        Asi mismo, en caso de poder eliminar el tier entonces todos los permisos asociados al tier se eliminan.
    
    Parámetros:
        - nombre_t : Nombre del tier a eliminar.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_tier(nombre_t TEXT)
RETURNS VOID AS $$
BEGIN
    IF NOT verify_exist_tier(nombre_t) THEN
        RAISE EXCEPTION 'El tier % no existe en el sistema.', nombre_t;
    END IF;

    IF EXISTS (SELECT 1 FROM suscrita WHERE nombre_tier = nombre_t) THEN
        RAISE EXCEPTION 'El tier % no puede ser eliminado porque tiene usuarios subscritos.', nombre_t;
    END IF;

    DELETE FROM tier WHERE nombre_tier = nombre_t;

    -- Nota: No hace falta eliminar los vinculos del tier con los permisos ya que al eliminar el tier se eliminan
    --       los permisos vinculados por CASCADE.
END;
$$ LANGUAGE plpgsql;

/*
    Función:
        delete_permission()

    Uso:
        Eliminar un permiso del sistema. Este permiso debe no estar relacionado con ningun tier, es decir
    
    Parámetros:
        - nombre_p : Nombre del permiso a eliminar.
    
    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_permission(nombre_p TEXT)
RETURNS VOID AS $$
BEGIN

    IF NOT verify_exist_permission(nombre_p) THEN
        RAISE EXCEPTION 'El permiso % no existe en el sistema.', nombre_p;
    END IF;

    IF EXISTS (SELECT 1 FROM maneja WHERE nombre_permiso = nombre_p) THEN
        RAISE EXCEPTION 'El permiso % no puede ser eliminado porque tiene tiers asociados.', nombre_p;
    END IF;

    DELETE FROM permiso WHERE nombre_permiso = nombre_p;

    -- Nota: No hace falta eliminar los vinculos del permiso con los tiers ya que al eliminar el permiso se eliminan
    --       los tiers vinculados por CASCADE.

END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_estudio_en()

    Uso:
        Eliminar una instancia en estudio_en 

    Parámetros:
        - id_user              : Id de la cuenta del usuario.
        - p_dominio            : Dominio de la institucion.
        - p_grado              : Grado de estudio.
        - p_especialidad       : Especialidad de estudio.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_estudio_en(id_user integer, p_dominio TEXT, p_grado TEXT, p_especialidad TEXT)
RETURNS void AS $$
BEGIN
    DELETE FROM estudio_en WHERE id_cuenta = id_user AND dominio = p_dominio AND grado = p_grado AND especialidad = p_especialidad;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_trabaja_en()

    Uso:
        Eliminar una instancia en trabaja_en.

    Parámetros:
        - id_user              : Id de la cuenta del usuario.
        - p_id_empresa         : Id de la empresa.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_trabaja_en(id_user integer, p_id_empresa integer)
RETURNS void AS $$  
BEGIN
    DELETE FROM trabaja_en WHERE id_cuenta = id_user AND id_empresa = p_id_empresa;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        get_super_likes_per_day()

    Uso:
        Calcular el numero de superlikes que da un usuario al dia.

    Parámetros: 
        - id_user  : Id del usuario a calcular.
        - from_day : Fecha a buscar.

    Retorna:
        Entero que representa el numero de likes dados en un dia.
*/
CREATE OR REPLACE FUNCTION get_super_likes_per_day(id_user INTEGER, from_day DATE)
RETURNS INTEGER AS $$
DECLARE
	super_likes_per_day INTEGER;
BEGIN
	SELECT COUNT(*) INTO super_likes_per_day
	FROM   likes 
	WHERE  id_liker = id_user AND DATE(fecha_like) = from_day AND super = TRUE;

	RETURN super_likes_per_day;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        change_permission_on_tiers

    Uso:
        Permite cambiar un permiso de un tier por otro en la tabla maneja.

    Parámetros:
        - nombre_tier_t     : Nombre del tier a desvincular con el permiso.
        - nombre_per_unlink : Nombre del permiso a desvincular con el tier.
        - nombre_per_link   : Nombre del nuevo permiso a vincular con el tier.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION change_permission_on_tiers(
    nombre_tier_t     TEXT,
    nombre_per_unlink TEXT,
    nombre_per_link   TEXT
) RETURNS VOID AS $$
BEGIN
    IF NOT verify_exist_tier(nombre_tier_t) THEN
        RAISE EXCEPTION 'El tier % no existe en el sistema.', nombre_tier_t;
    END IF;

    IF NOT verify_exist_permission(nombre_per_unlink) THEN
        RAISE EXCEPTION 'El permiso % no existe en el sistema.', nombre_per_unlink;
    END IF;

    IF NOT verify_exist_permission(nombre_per_link) THEN
        RAISE EXCEPTION 'El permiso % no existe en el sistema.', nombre_per_link;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM maneja WHERE nombre_tier = nombre_tier_t AND nombre_permiso = nombre_per_unlink) THEN
        RAISE EXCEPTION 'El tier % no tiene el permiso %.', nombre_tier_t, nombre_per_p;
    END IF;

    IF EXISTS (SELECT 1 FROM maneja WHERE nombre_tier = nombre_tier_t AND nombre_permiso = nombre_per_link) THEN
        RAISE EXCEPTION 'El tier % ya tiene el permiso %.', nombre_tier_t, nombre_per_link;
    END IF;

    DELETE FROM maneja WHERE nombre_tier = nombre_tier_t AND nombre_permiso = nombre_per_unlink;

    INSERT INTO maneja (nombre_tier, nombre_permiso)
    VALUES (nombre_tier_t, nombre_per_link);
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función: 
        delete_swipe()

    Uso: 
        Para que un usuario elimine un swipe que dio anteriormente
        con la condicion de que dicho usuario debe estar suscrito a un tier.

    Parámetros: 
        - id_user  : Id de quien elimina el dislike.
        - disliked : Id de quien se borra el dislike.

    Retorna:
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_swipe(id_user INT, disliked INT)
RETURNS VOID AS $$
BEGIN
    IF (check_if_user_has_a_permission(id_user, 'rewinds_ilimitados')) THEN 
        DELETE FROM swipes WHERE id_disliker = id_user AND id_disliked = disliked;
    ELSE
        RAISE EXCEPTION 'El usuario no tiene el permiso para realizar tal accion.';
    END IF;
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        check_due_card()

    Uso:
        Verificar si la tarjeta esta vencida al momento de realizar una compra.

    Parámetros:
        - digitostarjeta_dt : Numero de la tarjeta a verificar.

    Retorna:
        Bool, True si la tarjeta esta vencida, False si no lo esta.
*/
CREATE OR REPLACE FUNCTION check_due_card(digitostarjeta_dt TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tarjeta WHERE digitos_tarjeta = digitostarjeta_dt) THEN
        RAISE EXCEPTION 'La tarjeta % no existe en el sistema.', digitostarjeta_dt;
    END IF;

    RETURN (SELECT fecha_caducidad FROM tarjeta WHERE digitos_tarjeta = digitostarjeta_dt) > CURRENT_DATE;
    
END;
$$ LANGUAGE plpgsql;

/***********************************************************************************************************/
/*
    Función:
        delete_instance_registra()

    Uso:
        Elimina una instancia de la tabla registra.
    
    Parámetros:
        - user_id     : Valor entero que indica el id del usuario.
        - card_number : TEXT numero de la tarjeta.

    Retorna: 
        Nada.
*/
CREATE OR REPLACE FUNCTION delete_instance_registra(user_id INTEGER, card_number TEXT) 
RETURNS VOID AS $$
BEGIN
    DELETE FROM registra WHERE id_cuenta = user_id AND digitos_tarjeta = card_number;
END;
$$ LANGUAGE plpgsql;
