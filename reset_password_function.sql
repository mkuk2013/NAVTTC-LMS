-- SQL Function to Reset User Password (Admin Only)
-- Run this in your Supabase SQL Editor

-- Enable pgcrypto extension for password hashing
create extension if not exists "pgcrypto";

-- Create the admin password reset function
create or replace function admin_reset_password(target_user_id uuid, new_password text)
returns void
language plpgsql
security definer
as $$
begin
  -- Optional: Check if the executing user is an admin
  -- This depends on your 'profiles' table structure. 
  -- Uncomment the following lines if you want strict RLS enforcement at the function level.
  
  -- if auth.uid() is null then raise exception 'Not authenticated'; end if;
  -- if not exists (select 1 from public.profiles where uid = auth.uid() and role = 'admin') then
  --   raise exception 'Unauthorized: Only admins can reset passwords';
  -- end if;

  -- Update the user's password in auth.users
  update auth.users
  set encrypted_password = crypt(new_password, gen_salt('bf'))
  where id = target_user_id;
  
  -- Log the action (optional)
  -- insert into public.audit_logs (action, target_id, performed_by) values ('reset_password', target_user_id, auth.uid());
end;
$$;
