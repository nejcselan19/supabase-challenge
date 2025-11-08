-- supabase/seed.sql
-- Seed data for Calda Challenge - Step 3
-- --------------------------------------

---------------------------
-- 1) Dummy auth users
--    (NOT real login accounts, just to pass FK to auth.users)
---------------------------

insert into auth.users (id)
values
  ('00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000002'),
  ('00000000-0000-0000-0000-000000000003')
on conflict (id) do nothing;

---------------------------
-- 2) Profiles (1–1 with auth.users)
---------------------------

insert into public.profiles (id, first_name, last_name)
values
  ('00000000-0000-0000-0000-000000000001', 'John', 'Doe'),
  ('00000000-0000-0000-0000-000000000002', 'Jane', 'Smith'),
  ('00000000-0000-0000-0000-000000000003', 'Bob',  'Stone')
on conflict (id) do nothing;

---------------------------
-- 3) Items (catalog)
---------------------------

insert into public.items (name, price, stock)
values
  ('T-shirt',       19.99, 100),
  ('Mug',           12.99, 200),
  ('Sticker Pack',   4.99, 500),
  ('Hoodie',        49.99,  50),
  ('Cap',           24.99,  80);

---------------------------
-- 4) Orders (3 orders, one per profile)
---------------------------

insert into public.orders (profile_id, recipient_name, shipping_address)
values
  ('00000000-0000-0000-0000-000000000001', 'John Doe',   '123 Main Street'),
  ('00000000-0000-0000-0000-000000000002', 'Jane Smith', '456 Second Avenue'),
  ('00000000-0000-0000-0000-000000000003', 'Bob Stone',  '789 Third Road');

---------------------------
-- 5) Order items
--    3 orders, each with at least 2 items
---------------------------

insert into public.order_items (order_id, item_id, quantity)
values
  -- Order 1 (John Doe)
  (
    (select id from public.orders where recipient_name = 'John Doe' limit 1),
    (select id from public.items  where name = 'T-shirt'     limit 1),
    2
  ),
  (
    (select id from public.orders where recipient_name = 'John Doe' limit 1),
    (select id from public.items  where name = 'Sticker Pack' limit 1),
    3
  ),

  -- Order 2 (Jane Smith)
  (
    (select id from public.orders where recipient_name = 'Jane Smith' limit 1),
    (select id from public.items  where name = 'Hoodie'      limit 1),
    1
  ),
  (
    (select id from public.orders where recipient_name = 'Jane Smith' limit 1),
    (select id from public.items  where name = 'Cap'         limit 1),
    2
  ),

  -- Order 3 (Bob Stone)
  (
    (select id from public.orders where recipient_name = 'Bob Stone' limit 1),
    (select id from public.items  where name = 'Mug'          limit 1),
    1
  ),
  (
    (select id from public.orders where recipient_name = 'Bob Stone' limit 1),
    (select id from public.items  where name = 'Sticker Pack' limit 1),
    4
  );

---------------------------
-- 6) Item history (sample audit rows)
---------------------------

insert into public.item_history (item_id, profile_id, action_type, old_value, new_value)
values
  -- John creates the T-shirt item
  (
    (select id from public.items where name = 'T-shirt' limit 1),
    '00000000-0000-0000-0000-000000000001',
    'CREATE',
    null,
    '{"name":"T-shirt","price":"19.99","stock":100}'
  ),
  -- Jane updates the Hoodie item
  (
    (select id from public.items where name = 'Hoodie' limit 1),
    '00000000-0000-0000-0000-000000000002',
    'UPDATE',
    '{"name":"Hoodie","price":"44.99","stock":50}',
    '{"name":"Hoodie","price":"49.99","stock":50}'
  );