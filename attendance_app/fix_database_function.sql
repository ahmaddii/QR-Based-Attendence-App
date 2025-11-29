-- Fix for create_user_for_student function
-- This function needs SECURITY DEFINER to access auth.users table

-- IMPORTANT NOTE: This function is likely REDUNDANT because:
-- 1. Your Flutter app already calls auth.signUp() which creates the user
-- 2. The user should already exist in auth.users before inserting into students table
-- 3. This trigger might cause conflicts

-- Option 1: Fix the function with SECURITY DEFINER (if you want to keep it)
DROP FUNCTION IF EXISTS create_user_for_student() CASCADE;

CREATE OR REPLACE FUNCTION create_user_for_student()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- This allows access to auth.users
SET search_path = public, auth
AS $$
BEGIN
    -- FIXED: Use NEW.user_id instead of NEW.id
    -- NEW.id is the students table primary key
    -- NEW.user_id is the foreign key to auth.users
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = NEW.user_id) THEN
        -- Note: You can't directly INSERT into auth.users like this
        -- Supabase manages auth.users through auth.signUp()
        -- This will likely fail or cause issues
        
        -- If you really need this, you'd need to use Supabase's admin API
        -- But it's better to ensure the user exists before inserting into students
        RAISE WARNING 'User % does not exist in auth.users. User should be created via auth.signUp() first.', NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_create_user_for_student ON students;

CREATE TRIGGER trigger_create_user_for_student
  AFTER INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION create_user_for_student();

-- ============================================
-- Option 2: RECOMMENDED - Remove the trigger entirely
-- ============================================
-- Since auth.signUp() already creates the user, this trigger is redundant
-- Uncomment the lines below to remove it:

-- DROP TRIGGER IF EXISTS trigger_create_user_for_student ON students;
-- DROP FUNCTION IF EXISTS create_user_for_student() CASCADE;

