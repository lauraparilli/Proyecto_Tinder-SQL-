CREATE INDEX perfil_geo_index ON perfil USING GIST (coordenada);  -- para buscar personas por max distancia

CREATE INDEX pref_geo_index ON preferencias USING GIST (coordenada_origen); -- para buscar personas por coordenada origen

CREATE INDEX cuenta_age_index ON cuenta (fecha_nacimiento); -- para buscar personas por preferencias en max o min edad

CREATE INDEX tarjeta_fecha_caducidad_index ON tarjeta(fecha_caducidad); -- identificar rápidamente tarjetas caducadas.

CREATE INDEX perfil_sexo_index ON perfil (sexo); -- para buscar personas por preferencias en genero.

CREATE INDEX perfil_sexo_index ON perfil (sexo); -- para buscar personas por genero.

CREATE INDEX institucion_nombre_index ON institucion (nombre); -- por si existen miles de instituciones, y el usuario quiere buscar la institucion por su nombre al momento de llenar el registro de la cuenta

CREATE INDEX empresa_nombre_url_index ON empresa (nombre_empresa, url); -- para buscar si la empresa ya existe en la base de datos o no (se usa en la funcion insert_trabaja_en)
