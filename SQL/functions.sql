CREATE OR REPLACE FUNCTION insert_coordenada()
RETURNS TRIGGER AS
$$
BEGIN
	New.coordenada = ST_SetSRID(ST_MakePoint(New.longitud, New.latitud), 4326);
    RETURN NEW;
END;
$$
 LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_coordenada_origen()
RETURNS TRIGGER AS
$$
BEGIN
    IF New.longitud_origen IS NOT NULL AND New.latitud_origen IS NOT NULL THEN
        New.coordenada_origen = ST_SetSRID(ST_MakePoint(New.longitud_origen, New.latitud_origen), 4326);
    END IF;
    RETURN NEW;
END;
$$

LANGUAGE plpgsql;
