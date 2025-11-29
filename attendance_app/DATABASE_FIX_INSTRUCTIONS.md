# Database Function Fix Instructions

## Problem
The `create_user_for_student` function is getting "permission denied for table users" error because it doesn't have proper permissions to access the `auth.users` table.

## Solution

### Option 1: Add SECURITY DEFINER to the Function (Recommended)

1. Go to **Supabase Dashboard** → **Database** → **SQL Editor**

2. Run this SQL to fix your function:

```sql
-- Drop and recreate the function with SECURITY DEFINER
DROP FUNCTION IF EXISTS create_user_for_student() CASCADE;

CREATE OR REPLACE FUNCTION create_user_for_student()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER  -- This allows the function to run with elevated permissions
SET search_path = public, auth
AS $$
BEGIN
  -- Your existing function logic here
  -- Make sure to include all your original code
  
  RETURN NEW;
END;
$$;

-- Recreate the trigger
CREATE TRIGGER trigger_create_user_for_student
  AFTER INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION create_user_for_student();
```

### Option 2: Remove the Trigger (If Not Needed)

If the function is trying to create a user in `auth.users`, you might not need it because:
- `auth.signUp()` in your Flutter app already creates the user
- The trigger might be redundant

To remove it:

```sql
DROP TRIGGER IF EXISTS trigger_create_user_for_student ON students;
DROP FUNCTION IF EXISTS create_user_for_student() CASCADE;
```

### Option 3: Fix the Function Logic

If your function needs to access `auth.users`, make sure it's using the correct schema:

```sql
CREATE OR REPLACE FUNCTION create_user_for_student()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Access auth.users correctly
  -- Example: SELECT * FROM auth.users WHERE id = NEW.user_id;
  
  -- Or if you need to update something:
  -- UPDATE auth.users SET ... WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$;
```

## Steps to Apply the Fix

1. **Backup your database** (optional but recommended)
2. Go to Supabase Dashboard → Database → SQL Editor
3. Copy and paste the SQL from Option 1 above
4. **Important**: Replace the function body with your actual function logic
5. Click "Run" to execute
6. Try registering a student again

## Verify the Fix

After applying the fix, test by:
1. Registering a new student in your app
2. Check if the error is gone
3. Verify the student record is created correctly

## Common Issues

- **"function does not exist"**: Make sure you've included all the original function logic
- **"permission denied"**: Ensure `SECURITY DEFINER` is set
- **"schema does not exist"**: Make sure `SET search_path = public, auth` is included

## Need Help?

If you're not sure what your original function does:
1. Go to Supabase Dashboard → Database → Functions
2. Find `create_user_for_student`
3. Copy its definition
4. Add `SECURITY DEFINER` and `SET search_path = public, auth`
5. Recreate it

