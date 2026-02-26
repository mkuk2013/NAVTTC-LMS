-- Enable Row Level Security (if not already enabled)
ALTER TABLE exam_results ENABLE ROW LEVEL SECURITY;

-- 1. Allow Public Read Access (For Verification Page)
-- This allows anyone (including verify.html) to search for a certificate by ID
DROP POLICY IF EXISTS "Public can view certificate details" ON exam_results;
CREATE POLICY "Public can view certificate details"
ON exam_results FOR SELECT
TO anon, authenticated
USING (true);

-- 2. Allow Students to Update their own records (To save generated Certificate ID)
-- This allows the logged-in student to update their own row (e.g. adding certificate_id)
DROP POLICY IF EXISTS "Students can update their own results" ON exam_results;
CREATE POLICY "Students can update their own results"
ON exam_results FOR UPDATE
TO authenticated
USING (auth.uid() = student_id)
WITH CHECK (auth.uid() = student_id);

-- 3. Allow Students to Insert their own results (Standard exam submission)
DROP POLICY IF EXISTS "Students can insert their own results" ON exam_results;
CREATE POLICY "Students can insert their own results"
ON exam_results FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = student_id);

-- 4. Allow Admins to view all results (Optional, but good practice)
-- Assuming you have an 'admin' role or using service_role, but explicit policy helps
-- (Skipping specific admin role check for simplicity, usually admins use service key or specific role logic)
