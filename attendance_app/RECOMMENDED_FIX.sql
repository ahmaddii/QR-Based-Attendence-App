-- RECOMMENDED FIX: Remove the trigger entirely
-- 
-- Why? Your Flutter app already calls auth.signUp() which creates the user in auth.users
-- The trigger is trying to do something that's already done, and it's causing permission errors
--
-- The correct flow is:
-- 1. Flutter calls auth.signUp() -> creates user in auth.users ✅
-- 2. Flutter inserts into students table -> should just work ✅
-- 3. Trigger tries to create user again -> REDUNDANT and causes errors ❌

-- Remove the trigger and function
DROP TRIGGER IF EXISTS trigger_create_user_for_student ON students;
DROP FUNCTION IF EXISTS create_user_for_student() CASCADE;

-- That's it! Your app will work correctly now.
-- The user is already created by auth.signUp() before the students table insert.


