# NEXUS Budget OS

> Futuristic household budget tracker — weekly view, Supabase Auth + DB, GitHub Pages.

---

## Stack

| Layer    | Technology                     |
|----------|-------------------------------|
| Frontend | Vanilla HTML / CSS / JS        |
| Auth     | Supabase Auth (email + password)|
| Database | Supabase Postgres (JSONB)      |
| Hosting  | GitHub Pages                   |

---

## Setup (15 minutes)

### Step 1 — Create a Supabase project

1. Go to [https://supabase.com](https://supabase.com) and sign in.
2. Click **New project**.
3. Choose a name (e.g. `nexus-budget`), set a strong database password, pick a region close to you.
4. Wait ~2 minutes for the project to provision.

---

### Step 2 — Run the database schema

1. In your Supabase project, go to **SQL Editor** (left sidebar).
2. Click **New query**.
3. Paste the entire contents of `schema.sql` into the editor.
4. Click **Run** (or press `Ctrl+Enter`).
5. You should see a success message. Your `budgets` table is now ready with Row Level Security enabled.

---

### Step 3 — Get your API keys

1. In your Supabase project, go to **Project Settings → API**.
2. Copy two values:
   - **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
   - **anon / public key** — a long JWT string

---

### Step 4 — Configure the app

Open `index.html` and find these two lines near the top of the `<script>` block (around line 310):

```js
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace the placeholder strings with your actual values:

```js
const SUPABASE_URL      = 'https://xxxxxxxxxxxx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Save the file.

---

### Step 5 — Enable Email Auth in Supabase

1. Go to **Authentication → Providers**.
2. Make sure **Email** is enabled (it is by default).
3. *(Optional)* Under **Authentication → Email Templates**, customise your confirmation email.
4. *(Optional for testing)* Under **Authentication → Settings**, disable "Confirm email" so you can sign up without verifying — re-enable this in production.

---

### Step 6 — Push to GitHub

```bash
# Initialise a git repo inside the nexus-budget folder
cd nexus-budget
git init
git add .
git commit -m "Initial commit — NEXUS Budget OS"

# Create a repo on GitHub (e.g. nexus-budget), then:
git remote add origin https://github.com/YOUR_USERNAME/nexus-budget.git
git branch -M main
git push -u origin main
```

---

### Step 7 — Enable GitHub Pages

1. In your GitHub repo, go to **Settings → Pages**.
2. Under **Source**, select **Deploy from a branch**.
3. Choose **main** branch, **/ (root)** folder.
4. Click **Save**.
5. After ~1 minute, your app is live at:
   `https://YOUR_USERNAME.github.io/nexus-budget/`

---

### Step 8 — Whitelist your GitHub Pages URL in Supabase

Supabase needs to allow your GitHub Pages domain for auth redirects.

1. Go to **Authentication → URL Configuration** in Supabase.
2. Add your GitHub Pages URL to **Allowed Redirect URLs**:
   `https://YOUR_USERNAME.github.io/nexus-budget/`
3. Also update **Site URL** to the same value.
4. Click **Save**.

---

## Usage

| Action               | How                                                    |
|----------------------|--------------------------------------------------------|
| **Sign up**          | Open the app → SIGN UP tab → enter email + password    |
| **Sign in**          | SIGN IN tab → enter credentials                        |
| **Enter amounts**    | Click any cell in the weekly table → type the amount   |
| **Rename a row**     | Click the row name and edit inline                     |
| **Add a row**        | Click `+ ADD [CATEGORY] ENTRY` button                  |
| **Delete a row**     | Click the `×` button on the right of any row           |
| **Navigate months**  | Use the `‹` / `›` arrows next to the month title       |
| **Auto-save**        | All changes save to Supabase automatically (900ms debounce) |

---

## Data Model

One row per user per month in the `budgets` table:

```
budgets
├── id          uuid  (primary key)
├── user_id     uuid  (references auth.users)
├── month_key   text  ("2026-3" = April 2026)
├── data        jsonb { weeks: [1,8,15,22], rows: [...] }
├── created_at  timestamptz
└── updated_at  timestamptz
```

Row Level Security ensures users can only read/write their own data.

---

## Project Structure

```
nexus-budget/
├── index.html    ← Single-page app (all HTML, CSS, JS)
├── schema.sql    ← Run once in Supabase SQL Editor
└── README.md     ← This file
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Blank page after deploying | Check browser console for CORS errors; verify Supabase URL/key are correct |
| "Invalid login credentials" | Check email is confirmed (or disable email confirmation in Supabase Auth settings) |
| Data not saving | Open browser console and look for Supabase errors; check RLS policies ran correctly |
| Auth redirect loops | Add your GitHub Pages URL to Supabase → Authentication → URL Configuration |
