-- supabase/seed_cloud.sql
-- Seed data for Calda Challenge - cloud instance
-- NOTE: This assumes you already have at least 3 real profiles
--       created via the handle_new_auth_user trigger.

---------------------------
-- Items (same as local)
---------------------------

insert into public.items (name, price, stock)
values
  ('T-shirt',       19.99, 100),
  ('Mug',           12.99, 200),
  ('Sticker Pack',   4.99, 500),
  ('Hoodie',        49.99,  50),
  ('Cap',           24.99,  80);

---------------------------
-- Orders (3 orders, one per existing profile)
--    We map the first 3 profiles by created_at.
---------------------------

with profile_map as (
  select
    id,
    row_number() over (order by created_at) as rn
  from public.profiles
)
insert into public.orders (profile_id, recipient_name, shipping_address)
select
  id,
  case rn
    when 1 then 'John Doe'
    when 2 then 'Jane Smith'
    when 3 then 'Bob Stone'
  end as recipient_name,
  case rn
    when 1 then '123 Main Street'
    when 2 then '456 Second Avenue'
    when 3 then '789 Third Road'
  end as shipping_address
from profile_map
where rn <= 3;

---------------------------
-- Order items
--    Same idea as local: we find orders by recipient_name.
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
