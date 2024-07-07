-- Ejecutar esta funcion en un Query Tool sobre la BD y dropeara todas las tablas en tinder_viejos_egresados.
DO $$ 
DECLARE
    r record;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'tinder_viejos_egresados') LOOP
        EXECUTE 'drop table if exists tinder_viejos_egresados.' || quote_ident(r.tablename) || ' cascade';
    END LOOP;
END $$;
DROP TABLE IF EXISTS archivo CASCADE;