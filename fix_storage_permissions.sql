-- ==========================================
-- NAVTTC LMS - Storage Permissions Fix
-- ==========================================
-- This script ensures the personal_storage table exists
-- and has the correct RLS policies for students and admins.

-- 1. Create Table (if it was somehow missing or broken)
CREATE TABLE IF NOT EXISTS public.personal_storage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  public_id TEXT,
  size BIGINT,
  type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE public.personal_storage ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Students can manage their own files
DROP POLICY IF EXISTS "Users can manage their own files" ON public.personal_storage;
CREATE POLICY "Users can manage their own files" ON public.personal_storage
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4. Policy: Admins can manage all files (via profiles check)
DROP POLICY IF EXISTS "Admins can manage all files" ON public.personal_storage;
CREATE POLICY "Admins can manage all files" ON public.personal_storage
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE uid = auth.uid() AND role = 'admin'
    )
  );

-- Done. Fix finalized.
