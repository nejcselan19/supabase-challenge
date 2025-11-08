drop policy "Authenticated users can read item_history" on "public"."item_history";

drop policy "Authenticated users can CRUD items" on "public"."items";

drop policy "Authenticated users can read order_archive" on "public"."order_archive";

drop policy "Order items follow order ownership" on "public"."order_items";

drop policy "Orders are manageable by their owner" on "public"."orders";

drop policy "Profiles are manageable by their owner" on "public"."profiles";


  create policy "Authenticated users can read item_history"
  on "public"."item_history"
  as permissive
  for select
  to authenticated
using ((( SELECT auth.uid() AS uid) IS NOT NULL));



  create policy "Authenticated users can CRUD items"
  on "public"."items"
  as permissive
  for all
  to authenticated
using ((( SELECT auth.uid() AS uid) IS NOT NULL))
with check ((( SELECT auth.uid() AS uid) IS NOT NULL));



  create policy "Authenticated users can read order_archive"
  on "public"."order_archive"
  as permissive
  for select
  to authenticated
using ((( SELECT auth.uid() AS uid) IS NOT NULL));



  create policy "Order items follow order ownership"
  on "public"."order_items"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_items.order_id) AND (o.profile_id = ( SELECT auth.uid() AS uid))))))
with check ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_items.order_id) AND (o.profile_id = ( SELECT auth.uid() AS uid))))));



  create policy "Orders are manageable by their owner"
  on "public"."orders"
  as permissive
  for all
  to authenticated
using ((profile_id = ( SELECT auth.uid() AS uid)))
with check ((profile_id = ( SELECT auth.uid() AS uid)));



  create policy "Profiles are manageable by their owner"
  on "public"."profiles"
  as permissive
  for all
  to authenticated
using ((id = ( SELECT auth.uid() AS uid)))
with check ((id = ( SELECT auth.uid() AS uid)));



