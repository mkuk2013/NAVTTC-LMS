-- ==========================================
-- NAVTTC LMS v2.0 - Fix Admin Permissions (RLS)
-- ==========================================
-- This script updates RLS policies to allow Admins to manage all profiles.

-- 1. Drop old restrictive update policy
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- 2. Create new policy that allows both owner AND admins to update
CREATE POLICY "Users and Admins can update profiles" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id OR public.is_admin());

-- 3. Also allow Admins to delete profiles (Fallback for admin dashboard)
DROP POLICY IF EXISTS "Admins can delete profiles" ON public.profiles;
CREATE POLICY "Admins can delete profiles" 
ON public.profiles FOR DELETE 
USING (public.is_admin());

-- 4. Ensure Admins can insert profiles (if needed for manual creation)
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users and Admins can insert profiles" 
ON public.profiles FOR INSERT 
WITH CHECK (auth.uid() = id OR public.is_admin());

-- Done. Admins can now approve students.
