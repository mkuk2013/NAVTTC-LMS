-- Supabase RPC Function to allow Admins to PERMANENTLY delete a user and their profile.
-- IMPORTANT: Run this in your Supabase SQL Editor once to enable automated deletion.

CREATE OR REPLACE FUNCTION delete_user_via_admin(target_uid uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Ensures the function can delete from auth.users
AS $$
BEGIN
    -- 1. Security Check: Only allow if the requester is an admin or teacher
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access Denied: Only administrators can delete users.';
    END IF;

    -- 2. Cleanup Resources/Tasks if they were the owner (No CASCADE by default)
    -- Only relevant if teachers/admins are being deleted, but good practice.
    UPDATE public.resources SET uploaded_by = NULL WHERE uploaded_by = target_uid;
    UPDATE public.tasks SET created_by = NULL WHERE created_by = target_uid;

    -- 3. Delete from Profile table
    -- Most related data (submissions, comments) will CASCADE from here.
    DELETE FROM public.profiles WHERE uid = target_uid;

    -- 4. Delete from Supabase Auth (The "Hard Delete")
    DELETE FROM auth.users WHERE id = target_uid;
END;
$$;
