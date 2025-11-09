set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_other_orders_total(exclude_order_id uuid)
 RETURNS TABLE(total numeric)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce(sum(order_total), 0)::numeric as total
  from public.my_orders
  where order_id <> exclude_order_id;
$function$
;


