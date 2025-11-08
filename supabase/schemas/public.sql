
-- =========================================================
-- STEP 3: TABLES
-- =========================================================

----------------------------------------------------------------------
-- PROFILES
-- 1-1 with auth.users; id matches auth.users.id
----------------------------------------------------------------------

create table profiles (
    id uuid primary key
        references auth.users(id) on delete cascade,
    first_name  text        not null,
    last_name   text        not null,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

----------------------------------------------------------------------
-- ITEMS
----------------------------------------------------------------------

create table items (
    id          uuid primary key default gen_random_uuid(),
    name        text            not null,
    price       numeric(10, 2)  not null,
    stock       integer         not null,
    created_at  timestamptz     not null default now(),
    updated_at  timestamptz     not null default now()
);

----------------------------------------------------------------------
-- ORDERS
----------------------------------------------------------------------

create table orders (
    id               uuid primary key default gen_random_uuid(),
    profile_id       uuid        not null
        references public.profiles(id) on delete restrict,
    recipient_name   text        not null,
    shipping_address text        not null,
    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now()
);

----------------------------------------------------------------------
-- ORDER ITEMS
----------------------------------------------------------------------

create table order_items (
    id          uuid primary key default gen_random_uuid(),
    item_id     uuid        not null
        references public.items(id) on delete restrict,
    order_id    uuid        not null
        references public.orders(id) on delete cascade,
    quantity    integer     not null check (quantity > 0),
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),

    constraint order_items_unique unique (order_id, item_id)
);

----------------------------------------------------------------------
-- ITEM HISTORY
-- For tracking CREATE / UPDATE / DELETE on items
----------------------------------------------------------------------
create type operation as enum ('CREATE', 'UPDATE', 'DELETE');
create table item_history (
    id          uuid primary key default gen_random_uuid(),

    -- No foreign key, just UUID reference to allow deleting items or profiles while preserving items historical events.
    item_id     uuid        not null,
    profile_id  uuid        not null,

    action_type operation not null,
    old_value   jsonb,
    new_value   jsonb,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

----------------------------------------------------------------------
-- ORDER ARCHIVE
-- Used by the cron job (Step 8) to store summaries of deleted orders
----------------------------------------------------------------------

create table order_archive (
    id           uuid primary key default gen_random_uuid(),
    orders_count integer        not null,
    total_sum    numeric(10, 2) not null,
    created_at   timestamptz    not null default now(),
    updated_at   timestamptz    not null default now()
);


-- =========================================================
-- STEP 4: RLS & POLICIES
-- =========================================================

-- 1) Enable RLS on ALL tables in this schema
alter table profiles      enable row level security;
alter table items         enable row level security;
alter table orders        enable row level security;
alter table order_items   enable row level security;
alter table item_history  enable row level security;
alter table order_archive enable row level security;

-- 2) PROFILES
-- Each auth user manages only their own profile (id = auth.uid())
create policy "Profiles are manageable by their owner"
  on profiles
  for all
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- 3) ITEMS
-- Any authenticated user can CRUD items
create policy "Authenticated users can CRUD items"
  on items
  for all
  to authenticated
  using ((select auth.uid()) is not null)
  with check ((select auth.uid()) is not null);

-- 4) ORDERS
-- Only the user whose profile_id = auth.uid() can see / modify them
create policy "Orders are manageable by their owner"
  on orders
  for all
  to authenticated
  using (profile_id = (select auth.uid()))
  with check (profile_id = (select auth.uid()));

-- 5) ORDER ITEMS
-- Order items are only accessible if they belong to an order whose profile_id = auth.uid()
create policy "Order items follow order ownership"
  on order_items
  for all
  to authenticated
  using (
    exists (
      select 1
      from orders o
      where o.id = order_items.order_id
        and o.profile_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from orders o
      where o.id = order_items.order_id
        and o.profile_id = (select auth.uid())
    )
  );

-- 6) ITEM HISTORY
-- Only authenticated users can READ the change log (read-only)
create policy "Authenticated users can read item_history"
  on item_history
  for select
  to authenticated
  using ((select auth.uid()) is not null);

-- 7) ORDER ARCHIVE
-- Only authenticated users can READ archive records (read-only)
create policy "Authenticated users can read order_archive"
  on order_archive
  for select
  to authenticated
  using ((select auth.uid()) is not null);


-- =========================================================
-- STEP 5: MY ORDERS VIEW
-- Aggregates orders with their items in JSON array and relies on RLS via security_invoker
-- =========================================================

create view my_orders
with (security_invoker = true) as
select
    o.id           as order_id,
    o.profile_id   as profile_id,
    o.recipient_name,
    o.shipping_address,
    o.created_at,
    o.updated_at,
    -- total value of the order
    sum(oi.quantity * i.price) as order_total,
    -- JSON array of order items with quantities and line totals
    jsonb_agg(
        jsonb_build_object(
            'item_id',     i.id,
            'item_name',   i.name,
            'unit_price',  i.price,
            'quantity',    oi.quantity,
            'line_total',  oi.quantity * i.price
        )
        order by i.name
    ) as items
from orders o
join order_items oi on oi.order_id = o.id
join items i       on i.id = oi.item_id
group by
    o.id,
    o.profile_id,
    o.recipient_name,
    o.shipping_address,
    o.created_at,
    o.updated_at;


-- =========================================================
-- STEP 6: TRIGGERS (updated_at + item history + profiles)
-- =========================================================

-- 6.1 Generic helper to bump updated_at on write
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Attach to all tables with updated_at
create trigger set_updated_at_profiles
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger set_updated_at_items
before update on public.items
for each row
execute function public.set_updated_at();

create trigger set_updated_at_orders
before update on public.orders
for each row
execute function public.set_updated_at();

create trigger set_updated_at_order_items
before update on public.order_items
for each row
execute function public.set_updated_at();

create trigger set_updated_at_item_history
before update on public.item_history
for each row
execute function public.set_updated_at();

create trigger set_updated_at_order_archive
before update on public.order_archive
for each row
execute function public.set_updated_at();


-- 6.2 Log CREATE / UPDATE / DELETE on items into item_history
create or replace function public.log_item_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile_id uuid;
begin
  -- Use authenticated user when available, otherwise a fallback to '00000000-0000-0000-0000-000000000000'
  v_profile_id := coalesce(
    auth.uid(),
    '00000000-0000-0000-0000-000000000000'::uuid
  );

  if (tg_op = 'INSERT') then
    insert into public.item_history (item_id, profile_id, action_type, old_value, new_value)
    values (
      new.id,
      v_profile_id,
      'CREATE',
      null,
      to_jsonb(new)
    );

    return new;

  elsif (tg_op = 'UPDATE') then
    -- Only log if something actually changed on the row
    if new is distinct from old then
      insert into public.item_history (item_id, profile_id, action_type, old_value, new_value)
      values (
        new.id,
        v_profile_id,
        'UPDATE',
        to_jsonb(old),
        to_jsonb(new)
      );
    end if;

    return new;

  elsif (tg_op = 'DELETE') then
    insert into public.item_history (item_id, profile_id, action_type, old_value, new_value)
    values (
      old.id,
      v_profile_id,
      'DELETE',
      to_jsonb(old),
      null
    );

    return old;
  end if;

  -- Fallback (should not happen)
  return coalesce(new, old);
end;
$$;

create trigger items_log_history
after insert or update or delete on public.items
for each row
execute function public.log_item_history();


-- 6.3 Automatically create a profile when a new auth user is created
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_first_name text;
  v_last_name  text;
begin
  v_first_name := coalesce(new.raw_user_meta_data->>'first_name', 'Unknown');
  v_last_name  := coalesce(new.raw_user_meta_data->>'last_name', 'Unknown');

  insert into public.profiles (id, first_name, last_name)
  values (new.id, v_first_name, v_last_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();
