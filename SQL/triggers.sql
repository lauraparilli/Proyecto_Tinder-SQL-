CREATE TRIGGER institucion_insert_coordenada_trigger
BEFORE INSERT ON institucion
FOR EACH ROW
EXECUTE PROCEDURE insert_coordenada();

CREATE TRIGGER perfil_insert_coordenada_trigger
BEFORE INSERT ON perfil
FOR EACH ROW
EXECUTE PROCEDURE insert_coordenada();

CREATE TRIGGER set_latitud_longitud_origen_trigger
BEFORE INSERT ON preferencias
FOR EACH ROW
EXECUTE PROCEDURE set_latitud_longitud_origen();
