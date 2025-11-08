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
