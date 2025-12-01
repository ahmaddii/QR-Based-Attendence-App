-- QUICK FIX: RLS Policy for Students Table
-- Copy and paste this entire block into Supabase SQL Editor and run it

-- Enable RLS if not already enabled
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- Remove any conflicting policies
DROP POLICY IF EXISTS "Students can insert their own record" ON students;
DROP POLICY IF EXISTS "Allow authenticated users to insert students" ON students;
DROP POLICY IF EXISTS "Allow public insert" ON students;

-- Create the INSERT policy
-- This allows authenticated users to insert a student record where user_id matches their auth ID
CREATE POLICY "Students can insert their own record"
ON students
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- That's it! Now try registering a student again.


