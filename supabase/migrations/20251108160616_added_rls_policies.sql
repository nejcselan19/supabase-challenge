alter table "public"."item_history" enable row level security;

alter table "public"."items" enable row level security;

alter table "public"."order_archive" enable row level security;

alter table "public"."order_items" enable row level security;

alter table "public"."orders" enable row level security;

alter table "public"."profiles" enable row level security;


  create policy "Authenticated users can read item_history"
  on "public"."item_history"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "Authenticated users can CRUD items"
  on "public"."items"
  as permissive
  for all
  to public
using ((auth.uid() IS NOT NULL))
with check ((auth.uid() IS NOT NULL));



  create policy "Authenticated users can read order_archive"
  on "public"."order_archive"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "Order items follow order ownership"
  on "public"."order_items"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_items.order_id) AND (o.profile_id = auth.uid())))))
with check ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_items.order_id) AND (o.profile_id = auth.uid())))));



  create policy "Orders are manageable by their owner"
  on "public"."orders"
  as permissive
  for all
  to public
using ((profile_id = auth.uid()))
with check ((profile_id = auth.uid()));



  create policy "Profiles are manageable by their owner"
  on "public"."profiles"
  as permissive
  for all
  to public
using ((id = auth.uid()))
with check ((id = auth.uid()));



