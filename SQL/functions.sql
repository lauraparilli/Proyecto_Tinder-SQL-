CREATE OR REPLACE FUNCTION insert_coordenada()
RETURNS TRIGGER AS
$$
BEGIN
	New.coordenada = ST_SetSRID(ST_MakePoint(New.longitud, New.latitud), 4326);
    RETURN NEW;
END;
$$
 LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION set_latitud_longitud_origen()
RETURNS TRIGGER AS
$$
BEGIN
    IF New.longitud_origen IS NULL OR New.latitud_origen IS NULL THEN
        SELECT p.latitud, p.longitud INTO NEW.latitud_origen, NEW.longitud_origen
        FROM perfil p
        WHERE p.id_cuenta = NEW.id_cuenta;
    END IF;
	New.coordenada_origen = ST_SetSRID(ST_MakePoint(New.longitud_origen, New.latitud_origen), 4326);
    RETURN NEW;
END;
$$

LANGUAGE plpgsql;
