CREATE INDEX perfil_geo_index ON perfil USING GIST (ST_SetSRID(ST_MakePoint(longitud, latitud), 4326));

CREATE INDEX pref_geo_index ON preferencias USING GIST (ST_SetSRID(ST_MakePoint(latitud_origen, longitud_origen), 4326));

CREATE INDEX institucion_geo_index ON institucion USING GIST (ST_SetSRID(ST_MakePoint(latitud, longitud), 4326));