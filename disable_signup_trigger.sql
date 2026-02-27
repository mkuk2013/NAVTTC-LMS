-- ==========================================
-- NAVTTC LMS v1.0 - Trigger Isolation
-- ==========================================
-- Run this script to temporarily DISABLE the signup trigger.
-- This helps us find out if the 500 error is in the trigger OR SMTP.

-- 1. Drop the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Optional: Keep the function (it doesn't hurt if not called)

-- NOW: Go back to the website and try signing up.
-- IF IT WORKS: The problem is in the Trigger/Function logic.
-- IF IT STILL 500s: The problem is in the Supabase SMTP/Auth service.
