CREATE TRIGGER institucion_set_coordenada_trigger
BEFORE INSERT OR UPDATE ON institucion
FOR EACH ROW
EXECUTE PROCEDURE set_coordenada();

CREATE TRIGGER perfil_set_coordenada_trigger
BEFORE INSERT OR UPDATE ON perfil
FOR EACH ROW
EXECUTE PROCEDURE set_coordenada();

CREATE TRIGGER set_latitud_longitud_origen_trigger
BEFORE INSERT OR UPDATE ON preferencias 
FOR EACH ROW
EXECUTE PROCEDURE set_latitud_longitud_origen();
