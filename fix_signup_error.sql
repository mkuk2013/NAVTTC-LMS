-- ==========================================
-- NAVTTC LMS v2.0 - Signup Repair Script
-- ==========================================
-- This script cleans up "Zombie" users from Supabase Auth
-- who have no matching profile in the public.profiles table.

-- 1. Identify and delete users from Auth that are missing profiles
-- This is the most common reason for 500 errors on re-registration.
DELETE FROM auth.users 
WHERE id NOT IN (SELECT id FROM public.profiles)
AND aud = 'authenticated';

-- 2. Optional: If you know the specific email causing trouble, you can delete it manually:
-- DELETE FROM auth.users WHERE email = 'problem-email@example.com';
-- DELETE FROM public.profiles WHERE email = 'problem-email@example.com';

-- Done. Try signing up again now.
