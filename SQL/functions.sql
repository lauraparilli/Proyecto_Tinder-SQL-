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
 * Funcion: delete_due_card
 *
 * Uso: Eliminar tarjetas vencidas al momento de realizar una operacion en la tabla realiza 
 *
 * Parametros: Ninguna

 * Retorna: La funcion trigger retorna la tarjeta que se elimino
 */
CREATE OR REPLACE FUNCTION delete_due_card()
RETURNS TRIGGER 
AS $$
BEGIN
    DELETE FROM tarjeta WHERE tarjeta.fecha_caducidad < CURRENT_DATE;
    RETURN OLD;
END;
$$
LANGUAGE plpgsql;

/*
 * Funcion: insert_institution
 * 
 * Uso: Insertar una institucion a la base de datos
 *
 * Parametros:
 *  - i_dominio: dominio de la institucion
 *  - i_nombre: nombre de la institucion
 *  - i_tipo: tipo de la institucion
 *  - i_ano_fundacion: año de fundacion de la institucion
 *  - i_latitud: latitud de la institucion
 *  - i_longitud: longitud de la institucion
 *
 * Retorno: Nada
 */
CREATE OR REPLACE FUNCTION insert_institution(i_dominio TEXT, i_nombre TEXT, i_tipo TEXT, i_ano_fundacion INTEGER, i_latitud DECIMAL, i_longitud DECIMAL) 
RETURNS VOID AS $$
BEGIN
    INSERT INTO institucion VALUES (i_dominio, i_nombre, i_tipo, i_ano_fundacion, i_latitud, i_longitud);
END;

$$ LANGUAGE plpgsql;


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
 *   - idioma_u: Texto que representa el idioma preferido del usuario.
 *   - notificaciones_u: Valor booleano que indica si el usuario desea recibir notificaciones.
 *   - tema_u: Valor booleano que indica el tema preferido del usuario.
 *   - sexo_u: Texto que representa el sexo del usuario.
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
CREATE OR REPLACE FUNCTION create_new_user(nombre_u TEXT, apellido_u TEXT, fecha_nacimiento_u DATE, telefono_u TEXT, email_u TEXT, password_hash TEXT, idioma_u TEXT, notificaciones_u BOOLEAN, tema_u BOOLEAN, sexo_u TEXT, latitud_u DECIMAL(10, 8), longitud_u DECIMAL(11,8), foto_u TEXT[], dominio_institucion TEXT, titulo_u TEXT, anio_ingreso INTEGER, anio_egreso INTEGER) 
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


/*
* Funcion: update_info_account
*
* Uso: Actualiza la informacion de la cuenta de un usuario en la tabla de cuenta. Recordar que el usuario no puede cambiar su nombre ni apellido.
*
* Parametros:
*  - c_id_cuenta: Valor entero del ID de la cuenta del usuario
*  - c_email: (OPCIONAL) Texto con el nuevo email del usuario
*  - c_contrasena: (OPCIONAL) Texto con el nuevo hash de contrasena del usuario
*  - c_telefono: (OPCIONAL) Texto con el nuevo telefono del usuario
*  - c_idioma: (OPCIONAL) Texto con el nuevo idioma del usuario
*  - c_tema: (OPCIONAL) Texto con el nuevo tema del usuario
*  - c_notificaciones: (OPCIONAL) Valor booleano con el nuevo valor de notificaciones del usuario
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION update_info_account(
    c_id_cuenta INTEGER,
    c_email TEXT DEFAULT NULL,
    c_contrasena TEXT DEFAULT NULL,
    c_telefono TEXT DEFAULT NULL,
    c_idioma TEXT DEFAULT NULL,
    c_tema BOOLEAN DEFAULT NULL,
    c_notificaciones BOOLEAN DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE cuenta
    SET email = CASE WHEN c_email IS NOT NULL THEN c_email ELSE email END,
        contrasena = CASE WHEN c_contrasena IS NOT NULL THEN c_contrasena ELSE contrasena END,
        telefono = CASE WHEN c_telefono IS NOT NULL THEN c_telefono ELSE telefono END,
        idioma = CASE WHEN c_idioma IS NOT NULL THEN c_idioma ELSE idioma END,
        tema = CASE WHEN c_tema IS NOT NULL THEN c_tema ELSE tema END,
        notificaciones = CASE WHEN c_notificaciones IS NOT NULL THEN c_notificaciones ELSE notificaciones END
    WHERE id_cuenta = c_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: update_location_account
*
* Uso: Actualiza la ubicacion del usuario
*
* Parametros:
*   - p_id_cuenta: Valor entero que representa el id de la cuenta
*   - p_latitud: DECIMAL que representa la nueva latitud del usuario
*   - p_longitud: DECIMAL que representa la nueva longitud del usuario
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION update_location_account(p_id_cuenta INTEGER, p_latitud DECIMAL, p_longitud DECIMAL) 
RETURNS void AS
$$
BEGIN
    UPDATE perfil 
    SET latitud = p_latitud, 
        longitud = p_longitud 
    WHERE id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: updateDescriptionOnPerfil
* 
* Parametros: 
*  - id_cuenta: Valor entero del nombre del usuario a editar la descripcion del perfil
*  - new_descripcion: Texto con la nueva descripcion del perfil
*/
CREATE OR REPLACE FUNCTION updateDescriptionOnPerfil(id_user INTEGER, new_descripcion TEXT)
RETURNS VOID
AS $$
BEGIN
    UPDATE perfil SET descripcion = new_descripcion WHERE id_cuenta = id_user;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: update_sexo_perfil
*
* Uso: Actualiza el sexo de un perfil de una cuenta
*
* Parametros:
*   - p_id_cuenta: Valor entero que representa el id de la cuenta
*   - p_sexo: Texto que representa el sexo del perfil a modificar
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION update_sexo_perfil(p_id_cuenta integer, p_sexo text)
RETURNS void AS
$$
BEGIN
    UPDATE perfil
    SET sexo = p_sexo
    WHERE id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: check_verified_profile
*
* Uso: Verifica si el perfil de un usuario ha sido verificado o no 
* 
* Parametros:
* 	- user_id: id del usuario
*
* Retorna:
* 	- boolean: true si el perfil ha sido verificado, false en caso contrario
*/
CREATE OR REPLACE FUNCTION check_verified_profile(user_id integer) 
RETURNS boolean 
AS $$
DECLARE
    verified boolean;
BEGIN
    SELECT verificado INTO verified FROM perfil WHERE id_cuenta = user_id;
    RETURN verified;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: set_true_verificado
*
* Uso: Setea true cuando el usuario completo exitosamente el proceso de verificar perfil
*
* Parametros:
*   - p_id_cuenta: Valor entero que representa el id de la cuenta
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION set_true_verificado(p_id_cuenta integer)
RETURNS void AS
$$
BEGIN
    UPDATE perfil
    SET verificado = TRUE
    WHERE id_cuenta = p_id_cuenta;
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: insert_preferences
*
* Uso: Insertar las preferencias de un usuario en la tabla de preferencias.
*
* Parametros:
*  - p_id_cuenta: Valor entero del ID de la cuenta del usuario.
*  - p_estudio: (Opcional) TEXT del nivel de estudio del usuario.
*  - p_latitud_origen: (Opcional) DECIMAL de la latitud de preferencia del usuario.
*  - p_longitud_origen: (Opcional) DECIMAL de la longitud de preferencia del usuario.
*  - p_distancia_maxima: (Opcional) Valor entero de la distancia máxima de búsqueda del usuario.
*  - p_min_edad: (Opcional) Valor entero de la edad mínima de búsqueda del usuario.
*  - p_max_edad: (Opcional) Valor entero de la edad máxima de búsqueda del usuario.
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION insert_preferences(
    p_id_cuenta INTEGER,
    p_estudio TEXT DEFAULT NULL,
    p_latitud_origen DECIMAL(10, 8) DEFAULT NULL,
    p_longitud_origen DECIMAL(11, 8) DEFAULT NULL,
    p_distancia_maxima INTEGER DEFAULT 5,
    p_min_edad INTEGER DEFAULT 30,
    p_max_edad INTEGER DEFAULT 99
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
*    - p_id_cuenta: Valor entero del ID de la cuenta del usuario.
*    - p_estudio: (Opcional) TEXT del nivel de estudio del usuario.
*    - p_latitud_origen: (Opcional) DECIMAL de la latitud de preferencia del usuario.
*    - p_longitud_origen: (Opcional) DECIMAL de la longitud de preferencia del usuario.
*    - p_distancia_maxima: (Opcional) Valor entero de la distancia máxima de búsqueda del usuario.
*    - p_min_edad: (Opcional) Valor entero de la edad mínima de búsqueda del usuario.
*    - p_max_edad: (Opcional) Valor entero de la edad máxima de búsqueda del usuario.
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION update_preferences(
    p_id_cuenta INTEGER,
    p_estudio TEXT DEFAULT NULL,
    p_latitud_origen DECIMAL(10, 8) DEFAULT NULL,
    p_longitud_origen DECIMAL(11, 8) DEFAULT NULL,
    p_distancia_maxima INTEGER DEFAULT NULL,
    p_min_edad INTEGER DEFAULT NULL,
    p_max_edad INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE preferencias
    SET estudio = CASE WHEN p_estudio IS NOT NULL THEN p_estudio ELSE estudio END, 
        latitud_origen = CASE WHEN p_latitud_origen IS NOT NULL THEN p_latitud_origen ELSE latitud_origen END,
        longitud_origen = CASE WHEN p_longitud_origen IS NOT NULL THEN p_longitud_origen ELSE longitud_origen END,
        distancia_maxima = CASE WHEN p_distancia_maxima IS NOT NULL THEN p_distancia_maxima ELSE distancia_maxima END,
        min_edad = CASE WHEN p_min_edad IS NOT NULL THEN p_min_edad ELSE min_edad END,
        max_edad = CASE WHEN p_max_edad IS NOT NULL THEN p_max_edad ELSE max_edad END
    WHERE id_cuenta = p_id_cuenta;
END;
$$
 LANGUAGE plpgsql;

-- Ejemplo de uso SELECT update_preferences(p_id_cuenta := 19, p_estudio := 'Doctorado', p_distancia_maxima := 50);

/*
* Función: insert_pref_sexo
*
* Uso: Inserta una nueva preferencia de sexo para un usuario en la tabla de pref_sexo
* 
* Parametros: 
*  - p_id_cuenta: Valor entero del ID de la cuenta del usuario
*  - p_sexo: Texto que indica el nuevo sexo de preferencia del usuario
* 
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION insert_pref_sexo(p_id_cuenta INTEGER, p_sexo TEXT)
RETURNS VOID
AS $$
BEGIN
    INSERT INTO pref_sexo(id_cuenta, sexo) VALUES (p_id_cuenta, p_sexo);
END;
$$ LANGUAGE plpgsql;


/*
* Funcion: delete_pref_sexo
*
* Uso: Elimina una preferencia de sexo de un usuario en la tabla de pref_sexo
*
* Parametros:
*  - p_id_cuenta: Valor entero del ID de la cuenta del usuario
*  - p_sexo: Texto que indica el sexo a eliminar de las preferencias del usuario
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION delete_pref_sexo(p_id_cuenta INTEGER, p_sexo TEXT)
RETURNS VOID
AS $$
BEGIN
    DELETE FROM pref_sexo WHERE id_cuenta = p_id_cuenta AND sexo = p_sexo;
END;
$$ LANGUAGE plpgsql;



/*
* Funcion: insert_pref_orientacion_sexual
*
* Uso: Inserta una nueva preferencia de orientacion sexual para un usuario en la tabla de pref_orientacion_sexual
*
* Parametros:
*  - p_id_cuenta: Valor entero del ID de la cuenta del usuario
*  - p_orientacion_sexual: Texto que indica la nueva orientacion sexual de preferencia del usuario
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION insert_pref_orientacion_sexual(p_id_cuenta INTEGER, p_orientacion_sexual TEXT)
RETURNS VOID
AS $$
BEGIN
    INSERT INTO pref_orientacion_sexual(id_cuenta, orientacion_sexual) VALUES (p_id_cuenta, p_orientacion_sexual);
END;
$$ LANGUAGE plpgsql;

/*
* Funcion: delete_pref_orientacion_sexual
*
* Uso: Elimina una preferencia de orientacion sexual de un usuario en la tabla de pref_orientacion_sexual
*
* Parametros:
*  - p_id_cuenta: Valor entero del ID de la cuenta del usuario
*  - p_orientacion_sexual: Texto que indica la orientacion sexual a eliminar de las preferencias del usuario
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION delete_pref_orientacion_sexual(p_id_cuenta INTEGER, p_orientacion_sexual TEXT)
RETURNS VOID
AS $$
BEGIN
    DELETE FROM pref_orientacion_sexual WHERE id_cuenta = p_id_cuenta AND orientacion_sexual = p_orientacion_sexual;
END;
$$ LANGUAGE plpgsql;


/*
* Funcion: get_all_users_by_max_distance
*
* Uso: Obtener todos los IDs de los usuarios que se encuentren a una distancia máxima de un usuario dado (no se considera en el resultado el usuario dado)
*
* Parametros:
*  - user_id: Valor entero del Id de la cuenta del usuario a partir del cual se calculará la distancia.
*
* Retorno:
*  - Retorna una tabla con los IDs de los usuarios que se encuentren a una distancia máxima de un usuario dado.
*/
CREATE OR REPLACE FUNCTION get_all_users_by_max_distance(user_id INTEGER)
RETURNS TABLE (id_cuenta_at_max_distance INTEGER)  
AS $$
DECLARE 
    max_distance INTEGER := 5;  -- DEFAULT VALUE 5 km
BEGIN
    /* verificar si existe una instancia de preferencias del usuario */
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
* Funcion: insert_user_tarjeta
*
* Uso: cuando el usuario registra una tarjeta, se inserta una instancia en la tabla tarjeta (si es que aun no existen en la base de datos), y se asocia a la cuenta del usuario creando una instancia en la tabla registra
* 
* Parametros:
* 	- user_id: Valor entero que indica el id del usuario
* 	- card_number: TEXT numero de la tarjeta
*   - titular: TEXT nombre del titular de la tarjeta
*   - due_date: DATE fecha de vencimiento de la tarjeta
*   - cvv: TEXT codigo de seguridad de la tarjeta
*   - type_card: TEXT tipo de tarjeta
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION insert_user_tarjeta(user_id INT, card_number TEXT, titular TEXT, due_date DATE, cvv TEXT, type_card TEXT) 
RETURNS VOID 
AS $$
BEGIN
    /*chequear que no este vencida la tarjeta*/
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
* Funcion: delete_instance_registra
*
* Uso: Elimina una instancia de la tabla registra
* 
* Parametros:
* 	- user_id: Valor entero que indica el id del usuario
* 	- card_number: TEXT numero de la tarjeta
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION delete_instance_registra(user_id INTEGER, card_number TEXT) 
RETURNS VOID 
AS $$
BEGIN
    DELETE FROM registra WHERE id_cuenta = user_id AND digitos_tarjeta = card_number;
END;
$$ LANGUAGE plpgsql;

/*
 * Funcion: update_due_date_card
 *
 * Uso: Actualizar la fecha de vencimiento de una tarjeta
 *
 * Parametros: 
 *     - card_number: TEXT indica los numeros de la tarjeta a modificar fecha de caducidad
 *     - new_due_date: DATE indica la nueva fecha de vencimiento de la tarjeta
 *
 * Retorna: Ninguna
 */
CREATE OR REPLACE FUNCTION update_due_date_card(card_number TEXT, new_due_date DATE)
RETURNS VOID AS $$
BEGIN
    UPDATE tarjeta
    SET fecha_caducidad = new_due_date
    WHERE digitos_tarjeta = card_number;
END;
$$ LANGUAGE plpgsql;

/*
 * Funcion: insert_empresa
 * 
 * Uso: Insertar una empresa a la base de datos
 *
 * Parametros:
 *  - e_nombre: nombre de la empresa
 *  - e_url: url de la empresa
 *
 * Retorno: Nada
 */
CREATE OR REPLACE FUNCTION insert_empresa(e_nombre TEXT, e_url TEXT) 
RETURNS VOID AS $$
BEGIN
    INSERT INTO empresa(nombre_empresa, url)
    VALUES(e_nombre, e_url);
END;

$$ LANGUAGE plpgsql;



/*
* Funcion: get_all_public_info_about_user
*
* Uso: Obtener todos los datos que sean considerados como publico de un usuario con su id_cuenta (nombre, apellido, edad, sexo, descripcion, verificado, latitud y longitud para mostrar la ciudad y pais con Nominatim, dominios de las instituciones en que estudio, Ids de la empresa que trabaja, hobbies, habilidades, certificaciones, fotos, orientaciones sexuales) para mostrarse en el perfil
*
* Parametros:
*   - id_user: id de la cuenta del usuario
*
* Resultado: Devuelve una tabla de una fila con todos los datos (mencionados en el Uso) del usuario con el id_cuenta
*/
CREATE OR REPLACE FUNCTION get_all_public_info_about_user(id_user integer)
RETURNS TABLE (
    r_nombre CHARACTER VARYING,
    r_apellido CHARACTER VARYING,
    r_edad INTEGER,
    r_sexo sexos,
    r_descripcion CHARACTER VARYING,
    r_verificado BOOLEAN,
    r_latitud DECIMAL,
    r_longitud DECIMAL,
    r_instituciones CHARACTER VARYING[],
    r_empresas INTEGER[],
    r_hobbies hobbies[],
    r_certificaciones CHARACTER VARYING[],
    r_habilidades habilidades[],
    r_fotos BYTEA[],
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
            FROM estudio_en AS e
            WHERE e.id_cuenta = id_user
        ),
        ARRAY(
            SELECT t.id_empresa
            FROM trabaja_en AS t
            WHERE t.id_cuenta = id_user
        ),
        ARRAY(
            SELECT h.hobby
            FROM tiene_hobby AS h
            WHERE h.id_cuenta = id_user
        ),
        ARRAY(
            SELECT c.certificaciones
            FROM tiene_certificaciones AS c
            WHERE c.id_cuenta = id_user
        ),
        ARRAY(
            SELECT h.habilidad
            FROM tiene_habilidades AS h
            WHERE h.id_cuenta = id_user
        ),
        ARRAY(
            SELECT f.foto
            FROM tiene_foto as f
            WHERE f.id_cuenta = id_user
        ),
        ARRAY(
            SELECT o.orientacion_sexual
            FROM tiene_orientacion_sexual AS o
            WHERE o.id_cuenta = id_user
        )
    FROM cuenta, perfil
    WHERE cuenta.id_cuenta = perfil.id_cuenta AND cuenta.id_cuenta = id_user;
END;
$$ LANGUAGE plpgsql;


/*
 * Funcion: insert_new_tier_with_new_permissions
 * 
 * Uso: Insertar una nueva tier a la base de datos con sus nuevos permisos
 *
 * Parametros:
 *  - t_nombre: nombre de la nueva tier
 *  - p_nombre_permisos[]: lista de TEXT de nombres de nuevos permisos 
 *  - p_descripcion_permisos[]: Lista de TEXT de descripciones de nuevos permisos
 *
 * Retorno: Nada
 */
CREATE OR REPLACE FUNCTION insert_new_tier_with_new_permissions(t_nombre TEXT, p_nombre_permisos TEXT[], p_descripcion_permisos TEXT[])
RETURNS VOID AS $$
DECLARE
    nombre_permisos_size INT;
    descripcion_permisos_size INT;
    i INT;
BEGIN
    /* verificar que el size de las listas sean iguales */
    nombre_permisos_size := array_length(p_nombre_permisos, 1);
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
 * Funcion: insert_new_tier_with_old_permissions
 * 
 * Uso: Insertar una nueva tier a la base de datos con permisos ya existente en la base de datos
 *
 * Parametros:
 *  - t_nombre: nombre de la nueva tier
 *  - p_nombre_permisos[]: lista de TEXT de nombres de permisos 
 *
 * Retorno: Nada
 */
CREATE OR REPLACE FUNCTION insert_new_tier_with_old_permissions(t_nombre TEXT, p_nombre_permisos TEXT[])
RETURNS VOID AS $$
DECLARE
    nombre_permisos_size INT;
    i INT;
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
 * Funcion: insert_new_permission
 *
 * Uso: insertar un nuevo permiso a la base de datos y asociarlo con un tier
 * 
 * Parametros: 
 *      - p_nombre_permiso: nombre del permiso
 *      - p_descripcion_permiso: descripcion del permiso
 *      - p_nombre_tier: nombre del tier asociado
 *
 * Retorna: Nada
 */
CREATE OR REPLACE FUNCTION insert_new_permission(p_nombre_permiso TEXT, p_descripcion_permiso TEXT, p_nombre_tier TEXT) RETURNS VOID AS $$
BEGIN
    INSERT INTO permiso VALUES (p_nombre_permiso, p_descripcion_permiso);
    INSERT INTO maneja VALUES (p_nombre_tier, p_nombre_permiso);
END;
$$ LANGUAGE plpgsql;


/*
 * Funcion: insert_trabaja_en
 *
 * Uso: cuando el usuario quiere agregar en que empresa trabaja actualmente, se inserta una nueva instancia de empresa (si es que no existe en la bd) y se inserta una nueva instancia de trabaja_en
 * 
 * Parametros: 
 *      - id_user: Entero del id de la cuenta del usuario
 *      - e_nombre_empresa: TEXT con el nombre de la empresa
 *      - e_url_empresa: TEXT con el url de la empresa 
 *      - e_puesto: TEXT con el cargo del usuario en la empresa
 *      - e_fecha_inicio: DATE con la fecha de inicio en que trabaja en la empresa
 *
 * Retorna: Nada
 */
CREATE OR REPLACE FUNCTION insert_trabaja_en(id_user INT, e_nombre_empresa TEXT, e_url_empresa TEXT, e_puesto TEXT, e_fecha_inicio DATE) RETURNS VOID AS $$
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
* Funcion: insert_agrupation
*
* Uso: Insertar una agrupacion de un usuario en una institucion en la tabla esta_en_agrupacion
*
* Parametros:
*  - p_id_cuenta: Entero del id de la cuenta de un usuario
*  - p_id_dominio: TEXT dominio de una institucion
*  - p_agrupacion: TEXT de la agrupacion a insertar
*
* Retorna: Nada
*/

CREATE OR REPLACE FUNCTION insert_agrupation(p_id_cuenta integer, p_id_dominio TEXT, p_agrupacion TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO esta_en_agrupacion(id_cuenta, dominio, agrupacion)
    VALUES (p_id_cuenta, p_id_dominio, p_agrupacion);
END;
$$ LANGUAGE plpgsql;


/* 
* Funcion: get_all_info_about_a_user_estudio_en
* 
* Uso: Obtener todos los datos  (titulos, años de ingreso y egreso, y agrupaciones) de estudio_en dado por su dominio de institucion e id_cuenta
*
* Parametros: 
*  - p_id_cuenta: Entero del id de la cuenta de un usuario
*  - p_id_dominio: TEXT dominio de una institucion
*
* Retorna: Una tabla de una fila con los datos de estudio_en asociados a la id_cuenta = p_id_cuenta y dominio = p_id_dominio
*/
CREATE OR REPLACE FUNCTION get_all_info_about_a_user_estudio_en(p_id_cuenta integer, p_id_dominio TEXT)
RETURNS TABLE(r_titulo CHARACTER VARYING[], r_ano_ingreso INTEGER[], r_ano_egreso INTEGER[], agrupaciones CHARACTER VARYING[]) AS $$
BEGIN
    RETURN QUERY
    SELECT array_agg(titulo), array_agg(ano_ingreso), array_agg(ano_egreso), 
    ARRAY(
        SELECT a.agrupacion 
        FROM esta_en_agrupacion AS a
        WHERE a.id_cuenta = p_id_cuenta AND a.dominio = p_id_dominio
    )
    FROM (
        SELECT *
        FROM estudio_en
        WHERE id_cuenta = p_id_cuenta AND dominio = p_id_dominio
    ) GROUP BY dominio;
END;
$$ LANGUAGE plpgsql;

/* 
* Funcion: get_all_info_about_a_user_trabaja_en
* 
* Uso: Obtener todos los datos de trabaja_en (cargo y fechas de inicio) de un usuario en una empresa
*
* Parametros: 
*  - p_id_cuenta: Entero del id de la cuenta de un usuario
*  - p_id_empresa: Entero del id de la empresa en que trabaja
*
* Retorna: Una tabla de una fila con los datos de trabaja_en asociados a la id_cuenta = p_id_cuenta y id_empresa = p_id_empresa
*/
CREATE OR REPLACE FUNCTION get_all_info_about_a_user_trabaja_en(p_id_cuenta integer, p_id_empresa integer)
RETURNS TABLE(puesto CHARACTER VARYING, fecha_de_inicio DATE) AS $$
BEGIN
    RETURN QUERY
    SELECT cargo, fecha_inicio
    FROM trabaja_en
    WHERE id_cuenta = p_id_cuenta AND id_empresa = p_id_empresa;
END;
$$ LANGUAGE plpgsql;


/* 
* Funcion: update_visto_msj
* 
* Uso: Actualizar el true del visto de un mensaje en la tabla mensaje
*
* Parametros: 
*  - p_id_chat: entero que representa el id del chat
*  - p_nro_mensaje: entero que representa el nro del mensaje en el chat
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION update_visto_msj(p_id_chat integer, p_nro_mensaje integer) RETURNS void AS $$
BEGIN
    UPDATE mensaje
    SET visto = TRUE
    WHERE id_chat = p_id_chat AND numero_msj = p_nro_mensaje;
END;
$$ LANGUAGE plpgsql;

/* 
* Funcion: insert_hobbies
*
* Uso: Inserta un nuevo registro en la tabla tiene_hobby
*
* Parametros:
*  - p_user_id: Entero del id de la cuenta
*  - p_hobby: TEXT del hobby
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION insert_hobbies(p_user_id INTEGER, p_hobby TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_hobby (id_cuenta, hobby)
    VALUES (p_user_id, p_hobby);
END;
$$ LANGUAGE plpgsql;

/* 
* Funcion: insert_habilidad
*
* Uso: Inserta un nuevo registro en la tabla tiene_habilidades
*
* Parametros:
*  - p_user_id: Entero del id de la cuenta
*  - p_habilidad: TEXT del habilidad
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION insert_habilidades(p_user_id INTEGER, p_habilidad TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_habilidades (id_cuenta, habilidad)
    VALUES (p_user_id, p_habilidad);
END;
$$ LANGUAGE plpgsql;

/* 
* Funcion: insert_foto
*
* Uso: Inserta un nuevo registro en la tabla tiene_foto
*
* Parametros:
*  - p_user_id: Entero del id de la cuenta
*  - p_foto: BYTEA de la foto en formato base64
*
* Retorna: Nada
*/
CREATE OR REPLACE FUNCTION insert_foto(p_user_id INTEGER, p_foto BYTEA)
RETURNS VOID AS $$
BEGIN
    INSERT INTO tiene_foto (id_cuenta, foto) VALUES (p_user_id, decode(p_foto, 'base64'));
END;
$$ LANGUAGE plpgsql;
