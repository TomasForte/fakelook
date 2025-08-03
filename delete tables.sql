DO $$ 
DECLARE 
    _r RECORD;
BEGIN
    -- Disable foreign keys, triggers and other constraints
    EXECUTE 'SET session_replication_role = replica';

    -- Loop through all tables in the public schema
    FOR _r IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', _r.tablename);
    END LOOP;

    -- Re-enable foreign key constraints
    EXECUTE 'SET session_replication_role = DEFAULT';
END $$;
