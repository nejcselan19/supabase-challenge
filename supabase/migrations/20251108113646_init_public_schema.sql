create type "public"."operation" as enum ('CREATE', 'UPDATE', 'DELETE');


  create table "public"."item_history" (
    "id" uuid not null default gen_random_uuid(),
    "item_id" uuid not null,
    "profile_id" uuid not null,
    "action_type" public.operation not null,
    "old_value" jsonb,
    "new_value" jsonb,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );



  create table "public"."items" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "price" numeric(10,2) not null,
    "stock" integer not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );



  create table "public"."order_archive" (
    "id" uuid not null default gen_random_uuid(),
    "orders_count" integer not null,
    "total_sum" numeric(10,2) not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );



  create table "public"."order_items" (
    "id" uuid not null default gen_random_uuid(),
    "item_id" uuid not null,
    "order_id" uuid not null,
    "quantity" integer not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );



  create table "public"."orders" (
    "id" uuid not null default gen_random_uuid(),
    "profile_id" uuid not null,
    "recipient_name" text not null,
    "shipping_address" text not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );



  create table "public"."profiles" (
    "id" uuid not null,
    "first_name" text not null,
    "last_name" text not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


CREATE UNIQUE INDEX item_history_pkey ON public.item_history USING btree (id);

CREATE UNIQUE INDEX items_pkey ON public.items USING btree (id);

CREATE UNIQUE INDEX order_archive_pkey ON public.order_archive USING btree (id);

CREATE UNIQUE INDEX order_items_pkey ON public.order_items USING btree (id);

CREATE UNIQUE INDEX order_items_unique ON public.order_items USING btree (order_id, item_id);

CREATE UNIQUE INDEX orders_pkey ON public.orders USING btree (id);

CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);

alter table "public"."item_history" add constraint "item_history_pkey" PRIMARY KEY using index "item_history_pkey";

alter table "public"."items" add constraint "items_pkey" PRIMARY KEY using index "items_pkey";

alter table "public"."order_archive" add constraint "order_archive_pkey" PRIMARY KEY using index "order_archive_pkey";

alter table "public"."order_items" add constraint "order_items_pkey" PRIMARY KEY using index "order_items_pkey";

alter table "public"."orders" add constraint "orders_pkey" PRIMARY KEY using index "orders_pkey";

alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."order_items" add constraint "order_items_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE RESTRICT not valid;

alter table "public"."order_items" validate constraint "order_items_item_id_fkey";

alter table "public"."order_items" add constraint "order_items_order_id_fkey" FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE not valid;

alter table "public"."order_items" validate constraint "order_items_order_id_fkey";

alter table "public"."order_items" add constraint "order_items_quantity_check" CHECK ((quantity > 0)) not valid;

alter table "public"."order_items" validate constraint "order_items_quantity_check";

alter table "public"."order_items" add constraint "order_items_unique" UNIQUE using index "order_items_unique";

alter table "public"."orders" add constraint "orders_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE RESTRICT not valid;

alter table "public"."orders" validate constraint "orders_profile_id_fkey";

alter table "public"."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."profiles" validate constraint "profiles_id_fkey";

grant delete on table "public"."item_history" to "anon";

grant insert on table "public"."item_history" to "anon";

grant references on table "public"."item_history" to "anon";

grant select on table "public"."item_history" to "anon";

grant trigger on table "public"."item_history" to "anon";

grant truncate on table "public"."item_history" to "anon";

grant update on table "public"."item_history" to "anon";

grant delete on table "public"."item_history" to "authenticated";

grant insert on table "public"."item_history" to "authenticated";

grant references on table "public"."item_history" to "authenticated";

grant select on table "public"."item_history" to "authenticated";

grant trigger on table "public"."item_history" to "authenticated";

grant truncate on table "public"."item_history" to "authenticated";

grant update on table "public"."item_history" to "authenticated";

grant delete on table "public"."item_history" to "service_role";

grant insert on table "public"."item_history" to "service_role";

grant references on table "public"."item_history" to "service_role";

grant select on table "public"."item_history" to "service_role";

grant trigger on table "public"."item_history" to "service_role";

grant truncate on table "public"."item_history" to "service_role";

grant update on table "public"."item_history" to "service_role";

grant delete on table "public"."items" to "anon";

grant insert on table "public"."items" to "anon";

grant references on table "public"."items" to "anon";

grant select on table "public"."items" to "anon";

grant trigger on table "public"."items" to "anon";

grant truncate on table "public"."items" to "anon";

grant update on table "public"."items" to "anon";

grant delete on table "public"."items" to "authenticated";

grant insert on table "public"."items" to "authenticated";

grant references on table "public"."items" to "authenticated";

grant select on table "public"."items" to "authenticated";

grant trigger on table "public"."items" to "authenticated";

grant truncate on table "public"."items" to "authenticated";

grant update on table "public"."items" to "authenticated";

grant delete on table "public"."items" to "service_role";

grant insert on table "public"."items" to "service_role";

grant references on table "public"."items" to "service_role";

grant select on table "public"."items" to "service_role";

grant trigger on table "public"."items" to "service_role";

grant truncate on table "public"."items" to "service_role";

grant update on table "public"."items" to "service_role";

grant delete on table "public"."order_archive" to "anon";

grant insert on table "public"."order_archive" to "anon";

grant references on table "public"."order_archive" to "anon";

grant select on table "public"."order_archive" to "anon";

grant trigger on table "public"."order_archive" to "anon";

grant truncate on table "public"."order_archive" to "anon";

grant update on table "public"."order_archive" to "anon";

grant delete on table "public"."order_archive" to "authenticated";

grant insert on table "public"."order_archive" to "authenticated";

grant references on table "public"."order_archive" to "authenticated";

grant select on table "public"."order_archive" to "authenticated";

grant trigger on table "public"."order_archive" to "authenticated";

grant truncate on table "public"."order_archive" to "authenticated";

grant update on table "public"."order_archive" to "authenticated";

grant delete on table "public"."order_archive" to "service_role";

grant insert on table "public"."order_archive" to "service_role";

grant references on table "public"."order_archive" to "service_role";

grant select on table "public"."order_archive" to "service_role";

grant trigger on table "public"."order_archive" to "service_role";

grant truncate on table "public"."order_archive" to "service_role";

grant update on table "public"."order_archive" to "service_role";

grant delete on table "public"."order_items" to "anon";

grant insert on table "public"."order_items" to "anon";

grant references on table "public"."order_items" to "anon";

grant select on table "public"."order_items" to "anon";

grant trigger on table "public"."order_items" to "anon";

grant truncate on table "public"."order_items" to "anon";

grant update on table "public"."order_items" to "anon";

grant delete on table "public"."order_items" to "authenticated";

grant insert on table "public"."order_items" to "authenticated";

grant references on table "public"."order_items" to "authenticated";

grant select on table "public"."order_items" to "authenticated";

grant trigger on table "public"."order_items" to "authenticated";

grant truncate on table "public"."order_items" to "authenticated";

grant update on table "public"."order_items" to "authenticated";

grant delete on table "public"."order_items" to "service_role";

grant insert on table "public"."order_items" to "service_role";

grant references on table "public"."order_items" to "service_role";

grant select on table "public"."order_items" to "service_role";

grant trigger on table "public"."order_items" to "service_role";

grant truncate on table "public"."order_items" to "service_role";

grant update on table "public"."order_items" to "service_role";

grant delete on table "public"."orders" to "anon";

grant insert on table "public"."orders" to "anon";

grant references on table "public"."orders" to "anon";

grant select on table "public"."orders" to "anon";

grant trigger on table "public"."orders" to "anon";

grant truncate on table "public"."orders" to "anon";

grant update on table "public"."orders" to "anon";

grant delete on table "public"."orders" to "authenticated";

grant insert on table "public"."orders" to "authenticated";

grant references on table "public"."orders" to "authenticated";

grant select on table "public"."orders" to "authenticated";

grant trigger on table "public"."orders" to "authenticated";

grant truncate on table "public"."orders" to "authenticated";

grant update on table "public"."orders" to "authenticated";

grant delete on table "public"."orders" to "service_role";

grant insert on table "public"."orders" to "service_role";

grant references on table "public"."orders" to "service_role";

grant select on table "public"."orders" to "service_role";

grant trigger on table "public"."orders" to "service_role";

grant truncate on table "public"."orders" to "service_role";

grant update on table "public"."orders" to "service_role";

grant delete on table "public"."profiles" to "anon";

grant insert on table "public"."profiles" to "anon";

grant references on table "public"."profiles" to "anon";

grant select on table "public"."profiles" to "anon";

grant trigger on table "public"."profiles" to "anon";

grant truncate on table "public"."profiles" to "anon";

grant update on table "public"."profiles" to "anon";

grant delete on table "public"."profiles" to "authenticated";

grant insert on table "public"."profiles" to "authenticated";

grant references on table "public"."profiles" to "authenticated";

grant select on table "public"."profiles" to "authenticated";

grant trigger on table "public"."profiles" to "authenticated";

grant truncate on table "public"."profiles" to "authenticated";

grant update on table "public"."profiles" to "authenticated";

grant delete on table "public"."profiles" to "service_role";

grant insert on table "public"."profiles" to "service_role";

grant references on table "public"."profiles" to "service_role";

grant select on table "public"."profiles" to "service_role";

grant trigger on table "public"."profiles" to "service_role";

grant truncate on table "public"."profiles" to "service_role";

grant update on table "public"."profiles" to "service_role";


