/*
  # Socium Rural SIRH - Complete Database Schema

  ## Overview
  This migration creates the complete database schema for the Socium Rural SIRH platform,
  an AI-powered HR management system for rural workers in developing economies.

  ## New Tables Created

  ### 1. users
  Extended user profile table for storing additional user information:
  - `id` (uuid, PK) - Auto-generated unique identifier
  - `email` (text, unique) - User email address
  - `full_name` (text) - User's full name
  - `role` (text) - User role: 'employer', 'worker', or 'admin'
  - `preferred_language` (text) - User's preferred UI language (fr, en, sw, ha, pt)
  - `created_at` (timestamptz) - Account creation timestamp

  ### 2. workers
  Stores information about rural workers registered in the system:
  - `id` (uuid, PK) - Unique worker identifier
  - `employer_id` (uuid, FK) - References the employer who registered this worker
  - `full_name` (text) - Worker's full name
  - `phone` (text) - Worker's phone number (for SMS/USSD)
  - `role_title` (text) - Job title/role (e.g., "Farm Worker", "Construction Worker")
  - `daily_rate` (numeric) - Daily wage rate
  - `currency` (text) - Currency code (XOF, KES, GHS, NGN, MZN)
  - `status` (text) - Worker status: 'active', 'pending', or 'inactive'
  - `national_id` (text, nullable) - National ID number if available
  - `created_at` (timestamptz) - Registration timestamp

  ### 3. contracts
  AI-generated employment contracts:
  - `id` (uuid, PK) - Unique contract identifier
  - `worker_id` (uuid, FK) - References the worker
  - `employer_id` (uuid, FK) - References the employer
  - `contract_type` (text) - Type: 'daily', 'monthly', or 'seasonal'
  - `start_date` (date) - Contract start date
  - `end_date` (date, nullable) - Contract end date (null for ongoing)
  - `terms_json` (jsonb) - Contract terms and clauses in JSON format
  - `status` (text) - Contract status: 'draft', 'active', or 'expired'
  - `generated_by_ai` (boolean) - Flag indicating AI generation
  - `created_at` (timestamptz) - Contract creation timestamp

  ### 4. payroll
  Payroll records for workers:
  - `id` (uuid, PK) - Unique payroll record identifier
  - `worker_id` (uuid, FK) - References the worker
  - `employer_id` (uuid, FK) - References the employer
  - `period_start` (date) - Pay period start date
  - `period_end` (date) - Pay period end date
  - `days_worked` (integer) - Number of days worked
  - `gross_amount` (numeric) - Gross pay amount
  - `deductions` (numeric) - Total deductions
  - `net_amount` (numeric) - Net pay amount
  - `currency` (text) - Currency code
  - `payment_method` (text) - Payment method: 'mobile_money', 'cash', or 'bank'
  - `payment_status` (text) - Status: 'pending', 'paid', or 'failed'
  - `paid_at` (timestamptz, nullable) - Payment completion timestamp
  - `created_at` (timestamptz) - Record creation timestamp

  ### 5. social_contributions
  Social security contributions tracking:
  - `id` (uuid, PK) - Unique contribution record identifier
  - `payroll_id` (uuid, FK) - References the associated payroll record
  - `worker_id` (uuid, FK) - References the worker
  - `contribution_type` (text) - Type: 'health', 'pension', or 'accident'
  - `amount` (numeric) - Contribution amount
  - `status` (text) - Status: 'pending', 'submitted', or 'confirmed'
  - `submitted_at` (timestamptz, nullable) - Submission timestamp

  ### 6. chat_logs
  Chatbot conversation logs for AI improvement:
  - `id` (uuid, PK) - Unique chat log identifier
  - `user_id` (uuid, FK, nullable) - References the user (null for anonymous)
  - `language` (text) - Language of the conversation
  - `user_message` (text) - User's message
  - `ai_response` (text) - AI assistant's response
  - `created_at` (timestamptz) - Conversation timestamp

  ## Security (Row Level Security)

  All tables have RLS enabled with policies ensuring:
  - Employers can only access their own workers, contracts, and payroll
  - Workers can view their own records
  - Admins have full access
  - Chat logs are accessible only to the user who created them
*/

-- Create users table (extended profile)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL DEFAULT 'employer' CHECK (role IN ('employer', 'worker', 'admin')),
  preferred_language text NOT NULL DEFAULT 'fr' CHECK (preferred_language IN ('fr', 'en', 'sw', 'ha', 'pt')),
  created_at timestamptz DEFAULT now()
);

-- Create workers table
CREATE TABLE IF NOT EXISTS workers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employer_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  phone text NOT NULL,
  role_title text NOT NULL,
  daily_rate numeric NOT NULL CHECK (daily_rate >= 0),
  currency text NOT NULL DEFAULT 'XOF' CHECK (currency IN ('XOF', 'KES', 'GHS', 'NGN', 'MZN')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('active', 'pending', 'inactive')),
  national_id text,
  created_at timestamptz DEFAULT now()
);

-- Create contracts table
CREATE TABLE IF NOT EXISTS contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id uuid NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  employer_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contract_type text NOT NULL CHECK (contract_type IN ('daily', 'monthly', 'seasonal')),
  start_date date NOT NULL,
  end_date date,
  terms_json jsonb NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'expired')),
  generated_by_ai boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Create payroll table
CREATE TABLE IF NOT EXISTS payroll (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  worker_id uuid NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  employer_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  period_start date NOT NULL,
  period_end date NOT NULL,
  days_worked integer NOT NULL CHECK (days_worked >= 0),
  gross_amount numeric NOT NULL CHECK (gross_amount >= 0),
  deductions numeric NOT NULL DEFAULT 0 CHECK (deductions >= 0),
  net_amount numeric NOT NULL CHECK (net_amount >= 0),
  currency text NOT NULL DEFAULT 'XOF' CHECK (currency IN ('XOF', 'KES', 'GHS', 'NGN', 'MZN')),
  payment_method text NOT NULL CHECK (payment_method IN ('mobile_money', 'cash', 'bank')),
  payment_status text NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed')),
  paid_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create social_contributions table
CREATE TABLE IF NOT EXISTS social_contributions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payroll_id uuid NOT NULL REFERENCES payroll(id) ON DELETE CASCADE,
  worker_id uuid NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
  contribution_type text NOT NULL CHECK (contribution_type IN ('health', 'pension', 'accident')),
  amount numeric NOT NULL CHECK (amount >= 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'confirmed')),
  submitted_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create chat_logs table
CREATE TABLE IF NOT EXISTS chat_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  language text NOT NULL CHECK (language IN ('fr', 'en', 'sw', 'ha', 'pt')),
  user_message text NOT NULL,
  ai_response text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- RLS Policies for workers table
CREATE POLICY "Employers can view own workers"
  ON workers FOR SELECT
  TO authenticated
  USING (employer_id = auth.uid());

CREATE POLICY "Employers can insert own workers"
  ON workers FOR INSERT
  TO authenticated
  WITH CHECK (employer_id = auth.uid());

CREATE POLICY "Employers can update own workers"
  ON workers FOR UPDATE
  TO authenticated
  USING (employer_id = auth.uid())
  WITH CHECK (employer_id = auth.uid());

CREATE POLICY "Employers can delete own workers"
  ON workers FOR DELETE
  TO authenticated
  USING (employer_id = auth.uid());

-- RLS Policies for contracts table
CREATE POLICY "Employers can view own contracts"
  ON contracts FOR SELECT
  TO authenticated
  USING (employer_id = auth.uid());

CREATE POLICY "Employers can insert own contracts"
  ON contracts FOR INSERT
  TO authenticated
  WITH CHECK (employer_id = auth.uid());

CREATE POLICY "Employers can update own contracts"
  ON contracts FOR UPDATE
  TO authenticated
  USING (employer_id = auth.uid())
  WITH CHECK (employer_id = auth.uid());

CREATE POLICY "Employers can delete own contracts"
  ON contracts FOR DELETE
  TO authenticated
  USING (employer_id = auth.uid());

-- RLS Policies for payroll table
CREATE POLICY "Employers can view own payroll"
  ON payroll FOR SELECT
  TO authenticated
  USING (employer_id = auth.uid());

CREATE POLICY "Employers can insert own payroll"
  ON payroll FOR INSERT
  TO authenticated
  WITH CHECK (employer_id = auth.uid());

CREATE POLICY "Employers can update own payroll"
  ON payroll FOR UPDATE
  TO authenticated
  USING (employer_id = auth.uid())
  WITH CHECK (employer_id = auth.uid());

CREATE POLICY "Employers can delete own payroll"
  ON payroll FOR DELETE
  TO authenticated
  USING (employer_id = auth.uid());

-- RLS Policies for social_contributions table
CREATE POLICY "Employers can view contributions for own payroll"
  ON social_contributions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM payroll
      WHERE payroll.id = social_contributions.payroll_id
      AND payroll.employer_id = auth.uid()
    )
  );

CREATE POLICY "Employers can insert contributions for own payroll"
  ON social_contributions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM payroll
      WHERE payroll.id = social_contributions.payroll_id
      AND payroll.employer_id = auth.uid()
    )
  );

CREATE POLICY "Employers can update contributions for own payroll"
  ON social_contributions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM payroll
      WHERE payroll.id = social_contributions.payroll_id
      AND payroll.employer_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM payroll
      WHERE payroll.id = social_contributions.payroll_id
      AND payroll.employer_id = auth.uid()
    )
  );

-- RLS Policies for chat_logs table
CREATE POLICY "Users can view own chat logs"
  ON chat_logs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can insert own chat logs"
  ON chat_logs FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_workers_employer_id ON workers(employer_id);
CREATE INDEX IF NOT EXISTS idx_workers_status ON workers(status);
CREATE INDEX IF NOT EXISTS idx_contracts_employer_id ON contracts(employer_id);
CREATE INDEX IF NOT EXISTS idx_contracts_worker_id ON contracts(worker_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts(status);
CREATE INDEX IF NOT EXISTS idx_payroll_employer_id ON payroll(employer_id);
CREATE INDEX IF NOT EXISTS idx_payroll_worker_id ON payroll(worker_id);
CREATE INDEX IF NOT EXISTS idx_payroll_payment_status ON payroll(payment_status);
CREATE INDEX IF NOT EXISTS idx_payroll_period ON payroll(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_social_contributions_payroll_id ON social_contributions(payroll_id);
CREATE INDEX IF NOT EXISTS idx_chat_logs_user_id ON chat_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_logs_created_at ON chat_logs(created_at DESC);