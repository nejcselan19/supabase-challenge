create extension if not exists "pg_cron" with schema "pg_catalog";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.archive_old_orders()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_cutoff       timestamptz := now() - interval '7 days';
  v_orders_count integer;
  v_total_sum    numeric(10, 2);
begin
  -- using my_orders view
  select
    count(*)::integer,
    coalesce(sum(order_total), 0)::numeric(10, 2)
  into v_orders_count, v_total_sum
  from public.my_orders
  where created_at < v_cutoff;

  -- Nothing to archive
  if v_orders_count = 0 then
    return;
  end if;

  -- store count and sum in order_archive
  insert into public.order_archive (orders_count, total_sum)
  values (v_orders_count, v_total_sum);

  -- delete old orders (order_items are removed via ON DELETE CASCADE)
  delete from public.orders
  where created_at < v_cutoff;
end;
$function$
;


