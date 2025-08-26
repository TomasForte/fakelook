DO $$ 
DECLARE 
    _r RECORD;
	r RECORD;
BEGIN
    -- Disable foreign keys, triggers and other constraints
    EXECUTE 'SET session_replication_role = replica';

    -- Loop through all tables in the public schema
    FOR _r IN 
        SELECT tablename, schemaname 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', _r.tablename);
    END LOOP;

FOR r IN
    SELECT
        n.nspname AS schema_name,
        p.proname AS routine_name,
        pg_get_function_identity_arguments(p.oid) AS args,
        p.prokind /*this returns f for function and p for procedure*/
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
LOOP
    IF r.prokind = 'f' THEN
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I(%s);', r.schema_name, r.routine_name, r.args);
    ELSIF r.prokind = 'p' THEN
        EXECUTE format('DROP PROCEDURE IF EXISTS %I.%I(%s);', r.schema_name, r.routine_name, r.args);
    END IF;
END LOOP;

    -- Re-enable foreign key constraints
    EXECUTE 'SET session_replication_role = DEFAULT';
END $$;
