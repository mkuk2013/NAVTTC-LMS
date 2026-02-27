-- ==========================================
-- NAVTTC LMS v2.0 - Database Diagnostics
-- ==========================================
-- This script lists all triggers and functions to help debug the 500 error.

-- 1. List all triggers
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table as table_name, 
    action_statement as statement, 
    action_orientation as orientation, 
    action_timing as timing
FROM information_schema.triggers
WHERE event_object_schema = 'public' OR event_object_schema = 'auth';

-- 2. List all functions in public schema
SELECT 
    p.proname as function_name, 
    pg_get_functiondef(p.oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public';
