-- Fix the trigger function permissions
-- Since RLS is disabled, the issue is definitely the trigger function

-- Option 1: Remove the trigger completely (RECOMMENDED)
DROP TRIGGER IF EXISTS trigger_create_user_for_student ON students;
DROP FUNCTION IF EXISTS create_user_for_student() CASCADE;

-- That's it! Your app should work now.
-- The trigger was trying to access auth.users without proper permissions.

-- ============================================
-- Option 2: If you MUST keep the trigger, fix it with SECURITY DEFINER
-- ============================================
-- Uncomment the code below only if you really need the trigger:

/*
DROP TRIGGER IF EXISTS trigger_create_user_for_student ON students;
DROP FUNCTION IF EXISTS create_user_for_student() CASCADE;

CREATE OR REPLACE FUNCTION create_user_for_student()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- This is the key!
SET search_path = public, auth
AS $$
BEGIN
    -- Just validate, don't try to insert into auth.users
    -- The user should already exist from auth.signUp()
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = NEW.user_id) THEN
        RAISE WARNING 'User % should already exist from auth.signUp()', NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_create_user_for_student
  AFTER INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION create_user_for_student();
*/

