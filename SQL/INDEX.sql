/* 
    Equipo 1: Tinder para Viejos Egresados (RobbleAffinity)
    
    Integrantes: Ana Shek,         19-10096
			     Jhonaiker Blanco, 18-10784
				 Junior Lara,      17-10303
				 Laura Parilli,    17-10778

                    **** INDEX.sql ****

    Archivo SQL de creacion de indices para la BD de Tinder para Viejos Egresados.
*/

-- Para buscar personas por max distancia.
CREATE INDEX perfil_geo_index ON perfil USING GIST (coordenada);

-- Para buscar personas por coordenada origen.
CREATE INDEX pref_geo_index ON preferencias USING GIST (coordenada_origen);

-- Para buscar personas por preferencias en max o min edad.
CREATE INDEX cuenta_age_index ON cuenta (fecha_nacimiento);

-- Para buscar personas por preferencias en genero.
CREATE INDEX perfil_sexo_index ON perfil (sexo); 

-- Para buscar si la empresa ya existe en la base de datos o no (se usa en la funcion insert_trabaja_en).
CREATE INDEX empresa_nombre_url_index ON empresa (nombre_empresa, url);

-- Para buscar rapidamente las suscripciones expiradas y quitarle los permisos a los usuarios con suscripciones expiradas.
CREATE INDEX suscrita_fecha_caducidad_index ON suscrita(fecha_caducidad);

-- Para buscar personas por preferencia en orientacion sexual.
CREATE INDEX tiene_orientacion_sexual_index ON tiene_orientacion_sexual (orientacion_sexual);

-- Para buscar personas por su estudio.
CREATE INDEX estudio_en_grado ON estudio_en (grado);

-- Para buscar si un usuario tiene un permiso en particular segun su tier suscrita.
CREATE INDEX maneja_nombre_permiso ON maneja (nombre_permiso);

-- Para buscar los pagos realizados por una persona (por ejemplo en reclamos).
CREATE INDEX realiza_id_cuenta ON realiza (id_cuenta);

-- Para obtener los chats de un usuario cada vez que inicie sesión (el usuario puede ser id_cuenta1 o id_cuenta2)
CREATE INDEX chatea_con_id_cuenta1 ON chatea_con (id_cuenta1); 
CREATE INDEX chatea_con_id_cuenta2 ON chatea_con (id_cuenta2); 

-- Para buscar los usuarios que han dado like a un usuario.
-- Razon: Para el parmiso de un tier que requiere saber cuantas personas te han dado like.
CREATE INDEX likes_id_liked ON likes (id_liked);

-- Para buscar los usuarios que han dado swipes a un usuario.
-- Razon: Para el parmiso de un tier que requiere saber cuantas personas te han dado swipes.
CREATE INDEX swipes_id_disliked ON swipes (id_disliked);

-- Para buscar los archivos y tipo de archivo que un usuario tiene.
CREATE INDEX archivo_nombre_archivo ON archivo (nombre, tipo);

/*  
    NOTA: Segun internet, en PostgreSQL, cuando se define una clave primaria (PRIMARY KEY) sobre una 
          columna de una tabla, este campo se constituye automáticamente como un índice de tipo B-tree.
*/

/* *********************************************************************************************************************

    **** Razones de por que no colocamos indices en una tabla ****

- cuenta: 
    Solo se hace uso del id_cuenta para buscar usuarios, pero como id_cuenta ya es primary key, no hace falta indexarla.

- pago: 
    Para buscar un pago se puede hacer con el PK en digitos_tarjeta.

- tarjeta: 
    Ya se tiene el PK en digitos_tarjeta.

- tier: 
    Solamente tiene la columna nombre_tier que ya es PK.

- permiso: 
    Solamente se necesita el nombre_permiso (PK) para buscar algun permiso en particular.

- maneja: 
    Hay veces en que se necesita chequear si un usuario tiene un permiso en particular, entonces, en estos casos hay que buscar.

- Preferencias: 
    En preferencias, solo necesita buscar la preferencia de un usuario por su id_cuenta (PK).

- institucion: 
    Solo se busca las instituciones por su dominio (PK).

- trabaja_en: 
    Solo se busca que empresas trabaja un usuario, por lo tanto, con poner en el PK el id_cuenta antes de id_empresa es suficiente.

- dislikes: 
    No se requiere buscar a los usuarios que han dado dislike a otros usuarios, por lo tanto, no hace falta indexarlo.

- match_with: 
    No hace falta realizar ninguna búsqueda de una instancia en particular en ninguna de sus columnas.

- chat: 
    Su unica columna es el id_chat que ya está como PK.

- mensaje: 
    El usuario puede querer buscar una palabra en un mensaje, pero eso se puede hacer con el front.

- Todas las siguientes tablas:
    - esta_en_agrupacion
    - tiene_hobby
    - tiene_habilidades
    - tiene_foto
    - tiene_orientacion_sexual
    - tiene_certificaciones
    - pref_orientacion_sexual
    - pref_sexo
    
    No se requiere hacer una busqueda de algun elemento en particular. 
    Solo se realiza operaciones de insert y delete sobre estas tablas mediante el id_cuenta.

- NOTA: No se crea un index para buscar los chats o mensajes por el nombre de la persona, eso se puede hacer con el front.

**********************************************************************************************************************/


