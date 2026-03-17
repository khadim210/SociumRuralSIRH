/*
  # Fix Security and Performance Issues

  ## 1. Missing Foreign Key Indexes
    - Add index on social_contributions.worker_id
    - Add index on workers.user_id

  ## 2. RLS Performance Optimization
    - Replace all auth.uid() calls with (SELECT auth.uid()) in policies
    - This prevents re-evaluation for each row, improving query performance at scale
    - Affects all tables: users, workers, contracts, payroll, social_contributions, 
      chat_logs, businesses, accounting_entries, accounting_periods, 
      registration_documents, tax_obligations

  ## 3. Multiple Permissive Policies Resolution
    - Consolidate multiple SELECT/UPDATE policies into single policies with OR conditions
    - Affects: contracts, payroll, social_contributions, workers

  ## Security Note
    - All policies maintain the same security guarantees
    - Performance improvements do not compromise data access controls
    - Users still only access their own data
*/

-- ============================================
-- PART 1: Add Missing Foreign Key Indexes
-- ============================================

CREATE INDEX IF NOT EXISTS idx_social_contributions_worker_id 
  ON social_contributions(worker_id);

CREATE INDEX IF NOT EXISTS idx_workers_user_id 
  ON workers(user_id);

-- ============================================
-- PART 2: Fix RLS Policies with (SELECT auth.uid())
-- ============================================

-- Drop all existing policies that use direct auth.uid()
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

DROP POLICY IF EXISTS "Employers can view own workers" ON workers;
DROP POLICY IF EXISTS "Employers can insert own workers" ON workers;
DROP POLICY IF EXISTS "Employers can update own workers" ON workers;
DROP POLICY IF EXISTS "Employers can delete own workers" ON workers;
DROP POLICY IF EXISTS "Workers can view own profile" ON workers;
DROP POLICY IF EXISTS "Workers can update own profile" ON workers;

DROP POLICY IF EXISTS "Employers can view own contracts" ON contracts;
DROP POLICY IF EXISTS "Employers can insert own contracts" ON contracts;
DROP POLICY IF EXISTS "Employers can update own contracts" ON contracts;
DROP POLICY IF EXISTS "Employers can delete own contracts" ON contracts;
DROP POLICY IF EXISTS "Workers can view own contracts" ON contracts;

DROP POLICY IF EXISTS "Employers can view own payroll" ON payroll;
DROP POLICY IF EXISTS "Employers can insert own payroll" ON payroll;
DROP POLICY IF EXISTS "Employers can update own payroll" ON payroll;
DROP POLICY IF EXISTS "Employers can delete own payroll" ON payroll;
DROP POLICY IF EXISTS "Workers can view own payroll" ON payroll;

DROP POLICY IF EXISTS "Employers can view contributions for own payroll" ON social_contributions;
DROP POLICY IF EXISTS "Employers can insert contributions for own payroll" ON social_contributions;
DROP POLICY IF EXISTS "Employers can update contributions for own payroll" ON social_contributions;
DROP POLICY IF EXISTS "Workers can view own contributions" ON social_contributions;

DROP POLICY IF EXISTS "Users can view own chat logs" ON chat_logs;
DROP POLICY IF EXISTS "Users can insert own chat logs" ON chat_logs;

DROP POLICY IF EXISTS "Users can view own businesses" ON businesses;
DROP POLICY IF EXISTS "Users can create own businesses" ON businesses;
DROP POLICY IF EXISTS "Users can update own businesses" ON businesses;
DROP POLICY IF EXISTS "Users can delete own businesses" ON businesses;

DROP POLICY IF EXISTS "Users can view own accounting entries" ON accounting_entries;
DROP POLICY IF EXISTS "Users can create own accounting entries" ON accounting_entries;
DROP POLICY IF EXISTS "Users can update own accounting entries" ON accounting_entries;
DROP POLICY IF EXISTS "Users can delete own accounting entries" ON accounting_entries;

DROP POLICY IF EXISTS "Users can view own accounting periods" ON accounting_periods;
DROP POLICY IF EXISTS "Users can create own accounting periods" ON accounting_periods;
DROP POLICY IF EXISTS "Users can update own accounting periods" ON accounting_periods;
DROP POLICY IF EXISTS "Users can delete own accounting periods" ON accounting_periods;

DROP POLICY IF EXISTS "Users can view own registration documents" ON registration_documents;
DROP POLICY IF EXISTS "Users can create own registration documents" ON registration_documents;
DROP POLICY IF EXISTS "Users can update own registration documents" ON registration_documents;
DROP POLICY IF EXISTS "Users can delete own registration documents" ON registration_documents;

DROP POLICY IF EXISTS "Users can view own tax obligations" ON tax_obligations;
DROP POLICY IF EXISTS "Users can create own tax obligations" ON tax_obligations;
DROP POLICY IF EXISTS "Users can update own tax obligations" ON tax_obligations;
DROP POLICY IF EXISTS "Users can delete own tax obligations" ON tax_obligations;

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (id = (SELECT auth.uid()));

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

-- ============================================
-- WORKERS TABLE POLICIES (Consolidated)
-- ============================================

CREATE POLICY "Workers can view profile"
  ON workers FOR SELECT
  TO authenticated
  USING (
    employer_id = (SELECT auth.uid()) OR 
    user_id = (SELECT auth.uid())
  );

CREATE POLICY "Employers can insert workers"
  ON workers FOR INSERT
  TO authenticated
  WITH CHECK (employer_id = (SELECT auth.uid()));

CREATE POLICY "Workers can update profile"
  ON workers FOR UPDATE
  TO authenticated
  USING (
    employer_id = (SELECT auth.uid()) OR 
    user_id = (SELECT auth.uid())
  )
  WITH CHECK (
    employer_id = (SELECT auth.uid()) OR 
    user_id = (SELECT auth.uid())
  );

CREATE POLICY "Employers can delete workers"
  ON workers FOR DELETE
  TO authenticated
  USING (employer_id = (SELECT auth.uid()));

-- ============================================
-- CONTRACTS TABLE POLICIES (Consolidated)
-- ============================================

CREATE POLICY "Contracts can be viewed"
  ON contracts FOR SELECT
  TO authenticated
  USING (
    employer_id = (SELECT auth.uid()) OR
    EXISTS (
      SELECT 1 FROM workers
      WHERE workers.id = contracts.worker_id
      AND workers.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Employers can insert contracts"
  ON contracts FOR INSERT
  TO authenticated
  WITH CHECK (employer_id = (SELECT auth.uid()));

CREATE POLICY "Employers can update contracts"
  ON contracts FOR UPDATE
  TO authenticated
  USING (employer_id = (SELECT auth.uid()))
  WITH CHECK (employer_id = (SELECT auth.uid()));

CREATE POLICY "Employers can delete contracts"
  ON contracts FOR DELETE
  TO authenticated
  USING (employer_id = (SELECT auth.uid()));

-- ============================================
-- PAYROLL TABLE POLICIES (Consolidated)
-- ============================================

CREATE POLICY "Payroll can be viewed"
  ON payroll FOR SELECT
  TO authenticated
  USING (
    employer_id = (SELECT auth.uid()) OR
    EXISTS (
      SELECT 1 FROM workers
      WHERE workers.id = payroll.worker_id
      AND workers.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Employers can insert payroll"
  ON payroll FOR INSERT
  TO authenticated
  WITH CHECK (employer_id = (SELECT auth.uid()));

CREATE POLICY "Employers can update payroll"
  ON payroll FOR UPDATE
  TO authenticated
  USING (employer_id = (SELECT auth.uid()))
  WITH CHECK (employer_id = (SELECT auth.uid()));

CREATE POLICY "Employers can delete payroll"
  ON payroll FOR DELETE
  TO authenticated
  USING (employer_id = (SELECT auth.uid()));

-- ============================================
-- SOCIAL CONTRIBUTIONS TABLE POLICIES (Consolidated)
-- ============================================

CREATE POLICY "Social contributions can be viewed"
  ON social_contributions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM payroll
      WHERE payroll.id = social_contributions.payroll_id
      AND payroll.employer_id = (SELECT auth.uid())
    ) OR
    EXISTS (
      SELECT 1 FROM workers
      WHERE workers.id = social_contributions.worker_id
      AND workers.user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Employers can insert contributions"
  ON social_contributions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM payroll
      WHERE payroll.id = social_contributions.payroll_id
      AND payroll.employer_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Employers can update contributions"
  ON social_contributions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM payroll
      WHERE payroll.id = social_contributions.payroll_id
      AND payroll.employer_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM payroll
      WHERE payroll.id = social_contributions.payroll_id
      AND payroll.employer_id = (SELECT auth.uid())
    )
  );

-- ============================================
-- CHAT LOGS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own chat logs"
  ON chat_logs FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can insert own chat logs"
  ON chat_logs FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

-- ============================================
-- BUSINESSES TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own businesses"
  ON businesses FOR SELECT
  TO authenticated
  USING (owner_id = (SELECT auth.uid()));

CREATE POLICY "Users can create own businesses"
  ON businesses FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = (SELECT auth.uid()));

CREATE POLICY "Users can update own businesses"
  ON businesses FOR UPDATE
  TO authenticated
  USING (owner_id = (SELECT auth.uid()))
  WITH CHECK (owner_id = (SELECT auth.uid()));

CREATE POLICY "Users can delete own businesses"
  ON businesses FOR DELETE
  TO authenticated
  USING (owner_id = (SELECT auth.uid()));

-- ============================================
-- ACCOUNTING ENTRIES TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own accounting entries"
  ON accounting_entries FOR SELECT
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can create own accounting entries"
  ON accounting_entries FOR INSERT
  TO authenticated
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can update own accounting entries"
  ON accounting_entries FOR UPDATE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ))
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can delete own accounting entries"
  ON accounting_entries FOR DELETE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

-- ============================================
-- ACCOUNTING PERIODS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own accounting periods"
  ON accounting_periods FOR SELECT
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can create own accounting periods"
  ON accounting_periods FOR INSERT
  TO authenticated
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can update own accounting periods"
  ON accounting_periods FOR UPDATE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ))
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can delete own accounting periods"
  ON accounting_periods FOR DELETE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

-- ============================================
-- REGISTRATION DOCUMENTS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own registration documents"
  ON registration_documents FOR SELECT
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can create own registration documents"
  ON registration_documents FOR INSERT
  TO authenticated
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can update own registration documents"
  ON registration_documents FOR UPDATE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ))
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can delete own registration documents"
  ON registration_documents FOR DELETE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

-- ============================================
-- TAX OBLIGATIONS TABLE POLICIES
-- ============================================

CREATE POLICY "Users can view own tax obligations"
  ON tax_obligations FOR SELECT
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can create own tax obligations"
  ON tax_obligations FOR INSERT
  TO authenticated
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can update own tax obligations"
  ON tax_obligations FOR UPDATE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ))
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "Users can delete own tax obligations"
  ON tax_obligations FOR DELETE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = (SELECT auth.uid())
  ));