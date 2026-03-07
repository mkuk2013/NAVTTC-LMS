-- Create the table for system settings
CREATE TABLE IF NOT EXISTS system_settings (
    key character varying PRIMARY KEY,
    value text NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist so the script can be re-run safely
DROP POLICY IF EXISTS "Allow authenticated users to read settings" ON system_settings;
DROP POLICY IF EXISTS "Allow authenticated users to insert/update settings" ON system_settings;

-- Allow all authenticated users to read the key
-- (The notifyAllStudents function needs this to grab the key)
CREATE POLICY "Allow authenticated users to read settings" 
ON system_settings 
FOR SELECT 
TO authenticated 
USING (true);

-- Allow authenticated users to insert/update the key if it doesn't exist
-- (The exact admin check relies on your profiles table so we just allow authenticated for ease of use)
CREATE POLICY "Allow authenticated users to insert/update settings" 
ON system_settings 
FOR ALL 
TO authenticated 
USING (true)
WITH CHECK (true);

-- Insert the Brevo API Key
INSERT INTO system_settings (key, value)
VALUES ('brevo_api_key', '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')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
