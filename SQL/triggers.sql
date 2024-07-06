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

CREATE TRIGGER delete_due_card
BEFORE INSERT OR UPDATE OR DELETE ON realiza
FOR EACH ROW
EXECUTE PROCEDURE delete_due_card();

CREATE TRIGGER prevent_delete_any_row
BEFORE DELETE ON institucion
FOR EACH ROW
EXECUTE FUNCTION prevent_delete_any_row();

CREATE TRIGGER check_if_a_match_with_exists
AFTER INSERT ON likes
FOR EACH ROW
EXECUTE FUNCTION check_match_exists();
