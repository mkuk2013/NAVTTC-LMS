-- Supabase RPC Function to allow Admins to Reset User Passwords
-- Run this in your Supabase SQL Editor

CREATE OR REPLACE FUNCTION admin_reset_password(target_user_id UUID, new_password TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Ensures the function runs with admin privileges bypassing RLS
AS $$
BEGIN
  -- We assume your app checks if the CURRENT user is an admin before calling this.
  -- Update the auth.users table with the new encrypted password.
  -- Note: Supabase's auth schema handles the actual hashing when using the API, 
  -- but direct SQL requires using the internal built-in crypto functions if updating directly.
  
  -- The safest way to do this in Supabase without external crypto extensions is via the builtin admin API, 
  -- but since RPC is the requested method:
  
  UPDATE auth.users
  SET encrypted_password = crypt(new_password, gen_salt('bf'))
  WHERE id = target_user_id;

END;
$$;
