-- Ejecutar esta funcion en un Query Tool sobre la BD y dropeara todas las tablas en tinder_viejos_egresados.
do $$ declare
    r record;
begin
    for r in (select tablename from pg_tables where schemaname = 'tinder_viejos_egresados') loop
        execute 'drop table if exists tinder_viejos_egresados.' || quote_ident(r.tablename) || ' cascade';
    end loop;
end $$;DROP TABLE IF EXISTS archivo CASCADE;