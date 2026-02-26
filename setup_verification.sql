-- Add certificate_id column to exam_results table
ALTER TABLE exam_results 
ADD COLUMN IF NOT EXISTS certificate_id TEXT;

-- Create an index for faster lookups
CREATE INDEX IF NOT EXISTS idx_exam_results_certificate_id 
ON exam_results(certificate_id);

-- Update RLS policies to allow public read access to verify certificates
-- (Assuming we want public verification, otherwise only authenticated users can verify)
-- If we want public verification without login:
ALTER TABLE exam_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to certificate details"
ON exam_results FOR SELECT
USING (true);
