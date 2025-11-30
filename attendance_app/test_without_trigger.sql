-- Test: Temporarily disable the trigger to see if it's causing the issue
-- If this fixes the problem, then the trigger is definitely the issue

-- Disable the trigger temporarily
ALTER TABLE students DISABLE TRIGGER trigger_create_user_for_student;

-- Now try registering a student in your app
-- If it works, the trigger is the problem

-- To re-enable the trigger later (if needed):
-- ALTER TABLE students ENABLE TRIGGER trigger_create_user_for_student;

