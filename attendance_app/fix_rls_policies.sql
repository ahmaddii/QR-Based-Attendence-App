-- Fix RLS Policies for Students Table
-- Run this in Supabase SQL Editor

-- First, check if RLS is enabled (it should be)
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated users to insert students" ON students;
DROP POLICY IF EXISTS "Students can insert their own record" ON students;
DROP POLICY IF EXISTS "Allow public insert" ON students;

-- Option 1: Allow authenticated users to insert their own student record
-- This ensures the user_id matches the authenticated user's ID
CREATE POLICY "Students can insert their own record"
ON students
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Option 2: If Option 1 doesn't work, use this more permissive policy
-- (Only use if Option 1 fails - it's less secure)
-- CREATE POLICY "Allow authenticated users to insert students"
-- ON students
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (true);

-- Also ensure authenticated users can read their own records
DROP POLICY IF EXISTS "Students can read their own record" ON students;

CREATE POLICY "Students can read their own record"
ON students
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Allow authenticated users to update their own records (optional)
DROP POLICY IF EXISTS "Students can update their own record" ON students;

CREATE POLICY "Students can update their own record"
ON students
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);


