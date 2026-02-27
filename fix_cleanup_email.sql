-- ==========================================
-- NAVTTC LMS v2.0 - Targeted Signup Cleanup
-- ==========================================
-- This script completely removes a specific user from both 
-- Auth and Profiles to allow a fresh start.

-- 1. SET THE EMAIL YOU WANT TO CLEAN UP
-- Replace 'problem-email@example.com' with the actual email.
DO $$
DECLARE
    target_email TEXT := 'REPLACE_WITH_YOUR_EMAIL@gmail.com';
BEGIN
    -- Delete from profiles first (foreign key constraint)
    DELETE FROM public.profiles WHERE email = target_email;
    
    -- Delete from auth.users
    DELETE FROM auth.users WHERE email = target_email;

    RAISE NOTICE 'Cleanup complete for email: %', target_email;
END $$;
