-- ═══════════════════════════════════════════════════════════
--  Casa Rustia Budget OS — Supabase Schema  v3.0
--  SHARED HOUSEHOLD + REALTIME EDITION
--
--  UPGRADE NOTE: If you ran the old schema (v1/v2), this script
--  safely migrates it. If this is a fresh project, run as-is.
-- ═══════════════════════════════════════════════════════════

-- ── MIGRATION (safe on both new and existing projects) ──────
DO $$
BEGIN
  -- Drop old user-scoped unique constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_user_month_unique'
  ) THEN
    ALTER TABLE public.budgets DROP CONSTRAINT budgets_user_month_unique;
  END IF;

  -- Add last_edited_by column if missing
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'budgets'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'budgets'
      AND column_name  = 'last_edited_by'
  ) THEN
    ALTER TABLE public.budgets ADD COLUMN last_edited_by uuid REFERENCES auth.users(id);
  END IF;

  -- Make user_id nullable (now used as audit/last-editor field)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'budgets'
      AND column_name  = 'user_id'
      AND is_nullable  = 'NO'
  ) THEN
    ALTER TABLE public.budgets ALTER COLUMN user_id DROP NOT NULL;
  END IF;
END
$$;
-- ─────────────────────────────────────────────────────────────


-- ═══════════════════════════════════════════════════════════
--  1. BUDGETS TABLE
--     One row per calendar month, shared across the household.
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.budgets (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  month_key      text        NOT NULL,
  data           jsonb       NOT NULL DEFAULT '{}',
  last_edited_by uuid        REFERENCES auth.users (id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT budgets_month_key_unique UNIQUE (month_key)
);

CREATE INDEX IF NOT EXISTS budgets_month_key_idx ON public.budgets (month_key);


-- ═══════════════════════════════════════════════════════════
--  2. AUTO-UPDATE updated_at TRIGGER
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS budgets_updated_at ON public.budgets;
CREATE TRIGGER budgets_updated_at
  BEFORE UPDATE ON public.budgets
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- ═══════════════════════════════════════════════════════════
--  3. ROW LEVEL SECURITY
--     All authenticated users (household members) share access.
-- ═══════════════════════════════════════════════════════════

ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own budgets"              ON public.budgets;
DROP POLICY IF EXISTS "Users can insert own budgets"            ON public.budgets;
DROP POLICY IF EXISTS "Users can update own budgets"            ON public.budgets;
DROP POLICY IF EXISTS "Users can delete own budgets"            ON public.budgets;
DROP POLICY IF EXISTS "Household members can read all budgets"  ON public.budgets;
DROP POLICY IF EXISTS "Household members can insert budgets"    ON public.budgets;
DROP POLICY IF EXISTS "Household members can update budgets"    ON public.budgets;
DROP POLICY IF EXISTS "Household members can delete budgets"    ON public.budgets;

CREATE POLICY "Household members can read all budgets"
  ON public.budgets FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Household members can insert budgets"
  ON public.budgets FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Household members can update budgets"
  ON public.budgets FOR UPDATE
  USING  (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Household members can delete budgets"
  ON public.budgets FOR DELETE
  USING (auth.uid() IS NOT NULL);


-- ═══════════════════════════════════════════════════════════
--  4. REPLICA IDENTITY — required for realtime DELETE payloads
--     Without FULL, DELETE events only carry the primary key (id).
--     month_key would be absent from oldRow, breaking cache invalidation.
-- ═══════════════════════════════════════════════════════════

ALTER TABLE public.budgets REPLICA IDENTITY FULL;


-- ═══════════════════════════════════════════════════════════
--  5. ENABLE SUPABASE REALTIME
-- ═══════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE public.budgets;


-- ═══════════════════════════════════════════════════════════
--  DONE — schema v3.1 applied:
--    ✓  Shared month_key unique constraint
--    ✓  Shared household RLS (all auth users)
--    ✓  REPLICA IDENTITY FULL (DELETE realtime payloads include all columns)
--    ✓  Realtime publication enabled
--    ✓  last_edited_by audit column
--    ✓  updated_at auto-trigger
-- ═══════════════════════════════════════════════════════════
