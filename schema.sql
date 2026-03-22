-- ═══════════════════════════════════════════════════════════
--  Casa Rustia Budget OS — Supabase Schema
--  Run this in your Supabase project → SQL Editor
-- ═══════════════════════════════════════════════════════════

-- 1. BUDGETS TABLE
--    Stores one JSON blob per user per month.
--    month_key format: "YYYY-M"  (e.g. "2026-3" for April 2026)

create table if not exists public.budgets (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references auth.users (id) on delete cascade,
  month_key   text        not null,           -- e.g. "2026-3"
  data        jsonb       not null default '{}',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  constraint budgets_user_month_unique unique (user_id, month_key)
);

-- Index for fast per-user lookups
create index if not exists budgets_user_id_idx on public.budgets (user_id);

-- 2. AUTO-UPDATE updated_at TRIGGER

create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace trigger budgets_updated_at
  before update on public.budgets
  for each row execute procedure public.handle_updated_at();

-- 3. ROW LEVEL SECURITY (RLS)
--    Users can only read/write their own rows.

alter table public.budgets enable row level security;

-- Policy: select own rows
create policy "Users can read own budgets"
  on public.budgets for select
  using (auth.uid() = user_id);

-- Policy: insert own rows
create policy "Users can insert own budgets"
  on public.budgets for insert
  with check (auth.uid() = user_id);

-- Policy: update own rows
create policy "Users can update own budgets"
  on public.budgets for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Policy: delete own rows
create policy "Users can delete own budgets"
  on public.budgets for delete
  using (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════
--  DONE. Your budgets table is ready.
-- ═══════════════════════════════════════════════════════════
