CREATE INDEX perfil_geo_index ON perfil USING GIST (coordenada);  -- para buscar personas por max distancia

CREATE INDEX pref_geo_index ON preferencias USING GIST (coordenada_origen); -- para buscar personas por coordenada origen

CREATE INDEX cuenta_age_index ON cuenta (fecha_nacimiento); -- para buscar personas por preferencias en max o min edad

CREATE INDEX tarjeta_fecha_caducidad_index ON tarjeta(fecha_caducidad); -- identificar rápidamente tarjetas caducadas.

CREATE INDEX perfil_sexo_index ON perfil (sexo); -- para buscar personas por preferencias en genero.

CREATE INDEX empresa_nombre_url_index ON empresa (nombre_empresa, url); -- para buscar si la empresa ya existe en la base de datos o no (se usa en la funcion insert_trabaja_en)

CREATE INDEX suscrita_fecha_caducidad_index ON suscrita(fecha_caducidad); -- para buscar rapidamente las suscripciones expiradas y quitarle los permisos a los usuarios con suscripciones expiradas xD

CREATE INDEX tiene_orientacion_sexual_index ON tiene_orientacion_sexual (orientacion_sexual); -- para buscar personas por preferencia en orientacion sexual

CREATE INDEX estudio_en_grado ON estudio_en (grado); -- para buscar personas por su estudio

CREATE INDEX maneja_nombre_permiso ON maneja (nombre_permiso); -- para buscar si un usuario tiene un permiso en particular segun su tier suscrita

-- Nota: Segun internet, en PostgreSQL, cuando se define una clave primaria (PRIMARY KEY) sobre una columna de una tabla, este campo se constituye automáticamente como un índice de tipo B-tree.

/*
Razones de por que no colocamos indices en una tabla
- cuenta: Solo se hace uso del id_cuenta para buscar usuarios, pero como id_cuenta ya es primary key, no hace falta indexarla.  
- pago: por la funcionalidad del app, no necesitamos buscar algun pago en particular. 
- tarjeta: tampoco es necesario buscar alguna tarjeta en particular. Puede que se necesite buscar si existe una tarjeta en la bd antes de insertar una nueva, 
pero se puede hacer con el PK de digitos_tarjeta
- registra: tampoco es necesario buscar si alguien tiene registrada una tarjeta en particular
- realiza: puede que necesitemos buscar un pago por la persona quien lo realizo en caso de reclamos, pero rara vez ocurren los reclamos asi que no hace falta indexar el id_cuenta
- tier: solamente tiene la columna nombre_tier que ya es PK
- permiso: solamente se necesita el nombre_permiso (PK) para buscar algun permiso en particular
- maneja: hay veces en que se necesita chequear si un usuario tiene un permiso en particular, entonces, en estos casos hay que buscar 
- preferencias: en preferencias, solo necesita buscar la preferencia de un usuario por su id_cuenta (PK)
- institucion: solo se busca las instituciones por su dominio (PK)
- trabaja_en: solo se busca que empresas trabaja un usuario, por lo tanto, con poner en el PK el id_cuenta antes de id_empresa es suficiente.
- likes, dislikes: solo nos interesa ver si un usuario dio like al otro o no para crear el match 
o chequear si uno dio dislike a otro para que no pueda darle like. Pero con el PK en id_liker + id_liked basta, igual con el id_disliker + id_disliked en PK de swipes.
- match_with: no hace falta realizar ninguna búsqueda de una instancia en particular en ninguna de sus columnas.
- chat: su unica columna es el id_chat que ya está como PK
- mensaje: El usuario puede querer buscar una palabra en un mensaje, pero eso se puede hacer con el front
- archivo: Puede que necesitemos buscar por nombre de un archivo, pero como el nombre del archivo está incluido en el PK no hace falta.
- chatea_con:
- esta_en_agrupacion, tiene_hobby, tiene_habilidades, tiene_foto, tiene_orientacion_sexual, tiene_certificaciones, pref_orientacion_sexual y pref_sexo: 
estas tablas no se requiere hacer una busqueda de algun elemento en particular. Solo se realiza operaciones de insert y delete sobre estas tablas mediante el id_cuenta
*/

-- NOTA: no se crea un index para buscar los chats o mensajes por el nombre de la persona, eso se puede hacer con el front
