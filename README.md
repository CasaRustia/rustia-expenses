# Casa Rustia Budget OS — v3.0

> Futuristic household budget tracker — weekly view, shared realtime sync, Supabase Auth + DB, GitHub Pages.

---

## What's New in v3.0

| Feature | Detail |
|---|---|
| **Realtime sync** | All logged-in users see edits instantly via Supabase WebSocket |
| **Shared household model** | One budget per month, shared across all family members |
| **Adjacent-month prefetch** | Prev/next months load silently in the background |
| **Live badge** | `● LIVE SYNC` indicator in the topbar shows connection state |
| **Flash on remote edit** | Table flashes green when another user saves a change |
| **Audit column** | `last_edited_by` tracks who last saved each month row |

---

## Stack

| Layer    | Technology                      |
|----------|---------------------------------|
| Frontend | Vanilla HTML / CSS / JS         |
| Auth     | Supabase Auth (email + password)|
| Database | Supabase Postgres (JSONB)       |
| Realtime | Supabase Realtime (WebSocket)   |
| Hosting  | GitHub Pages                    |

---

## Setup (15 minutes)

### Step 1 — Create a Supabase project

1. Go to [https://supabase.com](https://supabase.com) and sign in.
2. Click **New project**, name it (e.g. `casa-rustia-budget`), set a password, pick a region.
3. Wait ~2 minutes for the project to provision.

---

### Step 2 — Run the database schema

1. In your Supabase project → **SQL Editor → New query**.
2. Paste the entire contents of `schema.sql`.
3. Click **Run**. You should see a success message.

> **Upgrading from v1/v2?** The schema includes a safe migration block at the top.
> It will drop the old per-user unique constraint, add `last_edited_by`, and
> enable the Realtime publication automatically.

---

### Step 3 — Enable Realtime for the budgets table

1. Go to **Database → Replication** (left sidebar).
2. Find the `budgets` table and make sure **INSERT**, **UPDATE**, and **DELETE** are all toggled on.

> The `ALTER PUBLICATION` line in `schema.sql` does this automatically,
> but it's worth double-checking in the UI.

---

### Step 4 — Get your API keys

1. **Project Settings → API**.
2. Copy **Project URL** and **anon / public key**.

---

### Step 5 — Configure the app

Open `index.html`, find these two lines near the top of the `<script>` block:

```js
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace with your actual values and save.

---

### Step 6 — Enable Email Auth

1. **Authentication → Providers** → confirm **Email** is enabled.
2. *(Optional for testing)* Under **Authentication → Settings**, disable "Confirm email".

---

### Step 7 — Push to GitHub & enable Pages

```bash
cd casa-rustia-budget
git init
git add .
git commit -m "Casa Rustia Budget OS v3.0"
git remote add origin https://github.com/YOUR_USERNAME/casa-rustia-budget.git
git branch -M main
git push -u origin main
```

Then: **GitHub repo → Settings → Pages → Deploy from branch → main / root → Save**.

---

### Step 8 — Whitelist your GitHub Pages URL in Supabase

1. **Authentication → URL Configuration**.
2. Add `https://YOUR_USERNAME.github.io/casa-rustia-budget/` to **Allowed Redirect URLs**.
3. Set the same URL as **Site URL**. Click **Save**.

---

## Usage

| Action | How |
|---|---|
| **Sign up / Sign in** | SIGN UP or SIGN IN tab on the login screen |
| **Enter amounts** | Click any cell in the weekly table → type the amount |
| **Rename a row** | Click the row name and edit inline |
| **Add a row** | Click `+ ADD [CATEGORY] ENTRY` button |
| **Delete a row** | Click the `×` button on the right of any row |
| **Navigate months** | Use the `‹` / `›` arrows next to the month title |
| **See who edited** | The topbar flashes `// SYNCED FROM ANOTHER USER` on remote changes |
| **Auto-save** | All changes save to Supabase automatically (900ms debounce) |
| **Realtime** | All household members see changes live — no refresh needed |

---

## Realtime Architecture

```
User A edits a cell
  └─► scheduleSave() debounce 900ms
       └─► saveMonth() → Supabase upsert (month_key only, no user_id filter)
            └─► Supabase broadcasts postgres_changes to all subscribers
                 └─► handleRealtimePayload() on User B & C
                      ├─► updates cache[month_key]
                      ├─► re-renders table (only if no local save pending)
                      └─► flashes table + shows sync indicator
```

Key safeguards:
- `self: false` on the channel — your own saves don't echo back and re-render
- `isRemoteUpdate` flag — remote patches never trigger a redundant re-save
- `saveTimer` guard — if a local save is in flight, incoming remote echoes are skipped

---

## Data Model

```
budgets
├── id              uuid  (primary key)
├── month_key       text  ("2026-3" = April 2026) ← UNIQUE, no user_id
├── data            jsonb { weeks: [1,8,15,22], rows: [...] }
├── last_edited_by  uuid  (references auth.users — audit trail)
├── created_at      timestamptz
└── updated_at      timestamptz
```

All authenticated household members share access via RLS policies.

---

## Project Structure

```
casa-rustia-budget/
├── index.html    ← Single-page app (all HTML, CSS, JS)
├── schema.sql    ← Run once in Supabase SQL Editor
└── README.md     ← This file
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `● LIVE SYNC` never appears | Check Supabase → Database → Replication → budgets table has INSERT/UPDATE/DELETE enabled |
| Table doesn't update on other devices | Confirm `ALTER PUBLICATION supabase_realtime ADD TABLE public.budgets` ran successfully |
| Blank page after deploying | Check browser console for CORS errors; verify Supabase URL/key |
| "Invalid login credentials" | Check email is confirmed or disable email confirmation in Supabase Auth |
| Data not saving | Open console, look for Supabase errors; check RLS policies ran correctly |
| Auth redirect loops | Add GitHub Pages URL to Supabase → Authentication → URL Configuration |
| Old data is per-user, new data is shared | Run the migration block in `schema.sql` — it safely drops the old per-user constraint |
