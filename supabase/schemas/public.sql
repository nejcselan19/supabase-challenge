
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
  using (id = auth.uid())
  with check (id = auth.uid());

-- 3) ITEMS
-- Any authenticated user can CRUD items
create policy "Authenticated users can CRUD items"
  on items
  for all
  using (auth.uid() is not null)
  with check (auth.uid() is not null);

-- 4) ORDERS
-- Only the user whose profile_id = auth.uid() can see / modify them
create policy "Orders are manageable by their owner"
  on orders
  for all
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- 5) ORDER ITEMS
-- Order items are only accessible if they belong to an order whose profile_id = auth.uid()
create policy "Order items follow order ownership"
  on order_items
  for all
  using (
    exists (
      select 1
      from orders o
      where o.id = order_items.order_id
        and o.profile_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from orders o
      where o.id = order_items.order_id
        and o.profile_id = auth.uid()
    )
  );

-- 6) ITEM HISTORY
-- Only authenticated users can READ the change log (read-only)
create policy "Authenticated users can read item_history"
  on item_history
  for select
  using (auth.uid() is not null);

-- 7) ORDER ARCHIVE
-- Only authenticated users can READ archive records (read-only)
create policy "Authenticated users can read order_archive"
  on order_archive
  for select
  using (auth.uid() is not null);

