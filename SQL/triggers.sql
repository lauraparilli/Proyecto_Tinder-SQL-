CREATE TRIGGER institucion_insert_coordenada_trigger
BEFORE INSERT ON institucion
FOR EACH ROW
EXECUTE PROCEDURE insert_coordenada();

CREATE TRIGGER perfil_insert_coordenada_trigger
BEFORE INSERT ON perfil
FOR EACH ROW
EXECUTE PROCEDURE insert_coordenada();

CREATE TRIGGER pref_insert_coordenada_origen_trigger
BEFORE INSERT ON preferencias
FOR EACH ROW
EXECUTE PROCEDURE insert_coordenada_origen();