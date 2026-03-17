/*
  # Create Socium Business Module Tables

  1. New Tables
    - `businesses`
      - Core business profile and registration status
      - Links to owner (employer) from users table
      - Tracks RC (Registre de Commerce) and NINEA/tax ID status
    
    - `accounting_entries`
      - Simple bookkeeping ledger
      - Tracks income, expenses, payroll, taxes, etc.
      - Supports receipts and reconciliation
    
    - `accounting_periods`
      - Monthly/quarterly/annual period summaries
      - Tracks totals and closure status
    
    - `registration_documents`
      - Stores uploaded documents for RC and NINEA applications
      - Tracks verification status
    
    - `tax_obligations`
      - Calendar of tax deadlines and payments
      - Tracks compliance status

  2. Security
    - Enable RLS on all tables
    - Business owners can only access their own data
    - All policies check ownership through businesses.owner_id
*/

-- Businesses table
CREATE TABLE IF NOT EXISTS businesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name text NOT NULL,
  business_type text,
  country text,
  region text,
  address text,
  phone text,
  founded_date date,
  rc_number text,
  ninea text,
  rc_status text DEFAULT 'none',
  ninea_status text DEFAULT 'none',
  rc_submitted_at timestamptz,
  rc_approved_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Accounting entries table
CREATE TABLE IF NOT EXISTS accounting_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES businesses(id) ON DELETE CASCADE,
  entry_date date DEFAULT CURRENT_DATE,
  entry_type text NOT NULL,
  category text,
  description text,
  amount numeric NOT NULL,
  currency text DEFAULT 'XOF',
  payment_method text DEFAULT 'cash',
  receipt_url text,
  is_reconciled boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Accounting periods table
CREATE TABLE IF NOT EXISTS accounting_periods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES businesses(id) ON DELETE CASCADE,
  period_start date NOT NULL,
  period_end date NOT NULL,
  total_income numeric DEFAULT 0,
  total_expenses numeric DEFAULT 0,
  net_result numeric DEFAULT 0,
  status text DEFAULT 'open',
  closed_at timestamptz
);

-- Registration documents table
CREATE TABLE IF NOT EXISTS registration_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES businesses(id) ON DELETE CASCADE,
  doc_type text NOT NULL,
  file_url text NOT NULL,
  status text DEFAULT 'pending',
  uploaded_at timestamptz DEFAULT now(),
  verified_at timestamptz
);

-- Tax obligations table
CREATE TABLE IF NOT EXISTS tax_obligations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES businesses(id) ON DELETE CASCADE,
  obligation_type text NOT NULL,
  due_date date NOT NULL,
  amount_due numeric NOT NULL,
  status text DEFAULT 'upcoming',
  paid_at timestamptz
);

-- Enable RLS
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounting_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounting_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE registration_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_obligations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for businesses
CREATE POLICY "Users can view own businesses"
  ON businesses FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own businesses"
  ON businesses FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own businesses"
  ON businesses FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete own businesses"
  ON businesses FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- RLS Policies for accounting_entries
CREATE POLICY "Users can view own accounting entries"
  ON accounting_entries FOR SELECT
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can create own accounting entries"
  ON accounting_entries FOR INSERT
  TO authenticated
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can update own accounting entries"
  ON accounting_entries FOR UPDATE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ))
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can delete own accounting entries"
  ON accounting_entries FOR DELETE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

-- RLS Policies for accounting_periods
CREATE POLICY "Users can view own accounting periods"
  ON accounting_periods FOR SELECT
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can create own accounting periods"
  ON accounting_periods FOR INSERT
  TO authenticated
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can update own accounting periods"
  ON accounting_periods FOR UPDATE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ))
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can delete own accounting periods"
  ON accounting_periods FOR DELETE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

-- RLS Policies for registration_documents
CREATE POLICY "Users can view own registration documents"
  ON registration_documents FOR SELECT
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can create own registration documents"
  ON registration_documents FOR INSERT
  TO authenticated
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can update own registration documents"
  ON registration_documents FOR UPDATE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ))
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can delete own registration documents"
  ON registration_documents FOR DELETE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

-- RLS Policies for tax_obligations
CREATE POLICY "Users can view own tax obligations"
  ON tax_obligations FOR SELECT
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can create own tax obligations"
  ON tax_obligations FOR INSERT
  TO authenticated
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can update own tax obligations"
  ON tax_obligations FOR UPDATE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ))
  WITH CHECK (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

CREATE POLICY "Users can delete own tax obligations"
  ON tax_obligations FOR DELETE
  TO authenticated
  USING (business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  ));

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_businesses_owner ON businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_business ON accounting_entries(business_id);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_date ON accounting_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_accounting_periods_business ON accounting_periods(business_id);
CREATE INDEX IF NOT EXISTS idx_registration_documents_business ON registration_documents(business_id);
CREATE INDEX IF NOT EXISTS idx_tax_obligations_business ON tax_obligations(business_id);
CREATE INDEX IF NOT EXISTS idx_tax_obligations_due_date ON tax_obligations(due_date);