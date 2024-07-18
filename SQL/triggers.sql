/* 
    Equipo 1: Tinder para Viejos Egresados (RobbleAffinity)
    
    Integrantes: Ana Shek,         19-10096
			     Jhonaiker Blanco, 18-10784
				 Junior Lara,      17-10303
				 Laura Parilli,    17-10778

                    **** TRIGGERS.sql ****

    Archivo SQL de creacion de triggers para la BD de Tinder para Viejos Egresados.
*/

CREATE OR REPLACE TRIGGER perfil_set_coordenada_trigger
BEFORE INSERT OR UPDATE ON perfil
FOR EACH ROW
EXECUTE PROCEDURE set_coordenada();

CREATE OR REPLACE TRIGGER set_latitud_longitud_origen_trigger
BEFORE INSERT OR UPDATE ON preferencias 
FOR EACH ROW
EXECUTE PROCEDURE set_latitud_longitud_origen();

CREATE OR REPLACE TRIGGER prevent_delete_any_row_institucion
BEFORE DELETE ON institucion
FOR EACH ROW
EXECUTE FUNCTION prevent_delete_any_row();

CREATE OR REPLACE TRIGGER check_if_a_match_with_exists
AFTER INSERT ON likes
FOR EACH ROW
EXECUTE FUNCTION check_match_exists();

CREATE OR REPLACE TRIGGER prevent_delete_any_row_pago
BEFORE DELETE ON pago
FOR EACH ROW
EXECUTE FUNCTION prevent_delete_any_row();

CREATE OR REPLACE TRIGGER prohibir_likes_and_superlikes
BEFORE INSERT ON likes
FOR EACH ROW
EXECUTE FUNCTION check_count_likes_or_superlikes();

CREATE OR REPLACE TRIGGER delete_agrupations_trigger
AFTER DELETE ON estudio_en
FOR EACH ROW
EXECUTE FUNCTION delete_agrupations();

