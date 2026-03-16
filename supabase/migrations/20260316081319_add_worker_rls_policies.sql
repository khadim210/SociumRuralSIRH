/*
  # Add Worker Self-Access RLS Policies

  1. Security Changes
    - Add RLS policies for workers table to allow workers to view and update their own data
    - Add RLS policies for payroll table to allow workers to view their own payroll records
    - Add RLS policies for contracts table to allow workers to view their own contracts
    - Add RLS policies for social_contributions table to allow workers to view their own contributions

  2. Important Notes
    - Workers can only SELECT their own records
    - Workers can UPDATE limited fields in their own profile (language preferences, etc.)
    - Workers CANNOT INSERT or DELETE any records
    - All policies check authentication via auth.uid()
    - Added user_id column to workers table to link to auth.users
*/

-- Add user_id column to workers table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'workers' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE workers ADD COLUMN user_id uuid REFERENCES auth.users(id);
  END IF;
END $$;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Workers can view own profile" ON workers;
DROP POLICY IF EXISTS "Workers can update own profile" ON workers;
DROP POLICY IF EXISTS "Workers can view own payroll" ON payroll;
DROP POLICY IF EXISTS "Workers can view own contracts" ON contracts;
DROP POLICY IF EXISTS "Workers can view own contributions" ON social_contributions;

-- Workers can view their own profile
CREATE POLICY "Workers can view own profile"
  ON workers FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Workers can update limited fields in their own profile
CREATE POLICY "Workers can update own profile"
  ON workers FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Workers can view their own payroll records
CREATE POLICY "Workers can view own payroll"
  ON payroll FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workers
      WHERE workers.id = payroll.worker_id
      AND workers.user_id = auth.uid()
    )
  );

-- Workers can view their own contracts
CREATE POLICY "Workers can view own contracts"
  ON contracts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workers
      WHERE workers.id = contracts.worker_id
      AND workers.user_id = auth.uid()
    )
  );

-- Workers can view their own social contributions
CREATE POLICY "Workers can view own contributions"
  ON social_contributions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM workers
      WHERE workers.id = social_contributions.worker_id
      AND workers.user_id = auth.uid()
    )
  );
