-- ==========================================
-- NAVTTC LMS v2.0 - Seed Users
-- ==========================================
-- This script safely injects the requested admin and student accounts into Supabase auth
-- and automatically sets up their public profiles.

-- Enable pgcrypto for password encryption
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
DECLARE
    admin_id UUID := gen_random_uuid();
    student_id UUID := gen_random_uuid();
BEGIN
    -- ==========================================
    -- 1. Create Admin User
    -- ==========================================
    INSERT INTO auth.users (
        id,
        instance_id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        admin_id,
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'mkuk2013@gmail.com',
        crypt('Admin@123+', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}',
        '{"role": "admin"}',
        now(),
        now(),
        '',
        '',
        '',
        ''
    );

    -- Insert Admin into public.profiles
    -- (Using ON CONFLICT just in case there's an insert trigger on auth.users creating the profile)
    INSERT INTO public.profiles (id, uid, full_name, email, role, status)
    VALUES (admin_id, admin_id, 'System Administrator', 'mkuk2013@gmail.com', 'admin', 'active')
    ON CONFLICT (id) DO UPDATE SET role = 'admin', status = 'active';


    -- ==========================================
    -- 2. Create Student User
    -- ==========================================
    INSERT INTO auth.users (
        id,
        instance_id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        student_id,
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'demostudent@gmail.com',
        crypt('demo123', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}',
        '{"role": "student"}',
        now(),
        now(),
        '',
        '',
        '',
        ''
    );

    -- Insert Student into public.profiles
    INSERT INTO public.profiles (id, uid, full_name, email, role, status)
    VALUES (student_id, student_id, 'Demo Student', 'demostudent@gmail.com', 'student', 'active')
    ON CONFLICT (id) DO UPDATE SET role = 'student', status = 'active';

END $$;
