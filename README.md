# Calda Challenge – Supabase Backend

Solution for the **Calda Backend Challenge**, built with **Supabase** (PostgreSQL, RLS, Edge Functions, RPC).  
All development was done locally with the Supabase CLI and tested both locally and on the cloud instance.

---

## ⚙️ Features

- Profiles linked to `auth.users`
- Tables: `profiles`, `items`, `orders`, `order_items`, `item_history`, `order_archive`
- RLS policies for secure, user-isolated access
- View: `my_orders` (aggregated JSON order overview)
- Triggers
- Edge Function: `create-order`
- Cron job: `archive_old_orders()` deletes >7-day-old orders and stores totals

---

## 🧩 Local Setup

```bash
# 1. Install dependencies
npm install

# 2. Start Supabase locally
npx supabase start

# 3. Reset & seed the database
npx supabase db reset
```

This runs `public.sql` and `seed.sql` to set up schema, triggers, and seed data.

---

## ☁️ Cloud Deployment

```bash
# Link project to Supabase cloud
npx supabase link --project-ref <project-ref>

# Push schema to cloud
npx supabase db push
```

Then run `supabase/seed_cloud.sql` manually in **Supabase Studio → SQL Editor**  
to seed items and orders for your real Auth users.

---

## 👤 Author
**Nejc Selan**  
Supabase Backend Challenge – 2025
