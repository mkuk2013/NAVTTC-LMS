-- ==========================================
-- NAVTTC LMS v2.0 - Fix Signup Trigger
-- ==========================================
-- This script (re)creates the trigger that automatically
-- links Supabase Auth users to the Profiles table.

-- 1. Create the function that handles new user insertion
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- We use COALESCE and NEW.raw_user_meta_data to get the name
  -- If 'name' is in options.data, it ends up in raw_user_meta_data
  INSERT INTO public.profiles (id, uid, full_name, email, role, status)
  VALUES (
    NEW.id, 
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email), 
    NEW.email, 
    'student', 
    'pending'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Bind the function to the auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Done. Trigger is now standardized.
