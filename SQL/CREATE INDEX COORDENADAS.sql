CREATE INDEX perfil_geo_index ON perfil USING GIST (coordenada);

CREATE INDEX pref_geo_index ON preferencias USING GIST (coordenada_origen);

