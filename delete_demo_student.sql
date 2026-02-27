-- ==========================================
-- NAVTTC LMS v2.0 - Delete Demo Student
-- ==========================================

-- 1. Delete from public.profiles table
DELETE FROM public.profiles WHERE email = 'demostudent@gmail.com';

-- 2. Delete from auth.users (Supabase Authentication Table)
DELETE FROM auth.users WHERE email = 'demostudent@gmail.com';

-- Done. Demo student data is wiped.
