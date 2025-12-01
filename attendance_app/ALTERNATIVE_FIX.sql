-- ALTERNATIVE FIX: Keep the trigger but fix it
-- Only use this if you have a specific reason to keep the trigger
-- Otherwise, use RECOMMENDED_FIX.sql instead

-- Drop existing function and trigger
DROP TRIGGER IF EXISTS trigger_create_user_for_student ON students;
DROP FUNCTION IF EXISTS create_user_for_student() CASCADE;

-- Recreate with SECURITY DEFINER and fixed logic
CREATE OR REPLACE FUNCTION create_user_for_student()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- This allows the function to access auth.users
SET search_path = public, auth
AS $$
BEGIN
    -- FIXED: Changed NEW.id to NEW.user_id
    -- NEW.id = students table primary key
    -- NEW.user_id = foreign key to auth.users (the actual user ID)
    
    -- Check if user exists (it should, since auth.signUp() was called first)
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = NEW.user_id) THEN
        -- Log a warning but don't fail
        -- The user should already exist from auth.signUp()
        RAISE WARNING 'User % does not exist in auth.users. This should not happen if registration flow is correct.', NEW.user_id;
    END IF;
    
    -- Note: You CANNOT directly INSERT into auth.users
    -- Supabase manages auth.users through its auth system
    -- If you need to create users, use auth.signUp() in your app
    
    RETURN NEW;
END;
$$;

-- Recreate the trigger
CREATE TRIGGER trigger_create_user_for_student
  AFTER INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION create_user_for_student();

-- IMPORTANT: This trigger is now just for validation/logging
-- It won't try to insert into auth.users (which would fail anyway)
-- The actual user creation happens via auth.signUp() in your Flutter app



