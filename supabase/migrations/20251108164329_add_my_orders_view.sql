create or replace view "public"."my_orders" as  SELECT o.id AS order_id,
    o.profile_id,
    o.recipient_name,
    o.shipping_address,
    o.created_at,
    o.updated_at,
    sum(((oi.quantity)::numeric * i.price)) AS order_total,
    jsonb_agg(jsonb_build_object('item_id', i.id, 'item_name', i.name, 'unit_price', i.price, 'quantity', oi.quantity, 'line_total', ((oi.quantity)::numeric * i.price)) ORDER BY i.name) AS items
   FROM ((public.orders o
     JOIN public.order_items oi ON ((oi.order_id = o.id)))
     JOIN public.items i ON ((i.id = oi.item_id)))
  GROUP BY o.id, o.profile_id, o.recipient_name, o.shipping_address, o.created_at, o.updated_at;



