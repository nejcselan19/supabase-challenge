set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_first_name text;
  v_last_name  text;
begin
  v_first_name := coalesce(new.raw_user_meta_data->>'first_name', 'N/A');
  v_last_name  := coalesce(new.raw_user_meta_data->>'last_name', 'N/A');

  insert into public.profiles (id, first_name, last_name)
  values (new.id, v_first_name, v_last_name)
  on conflict (id) do nothing;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.log_item_history()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE TRIGGER set_updated_at_item_history BEFORE UPDATE ON public.item_history FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER items_log_history AFTER INSERT OR DELETE OR UPDATE ON public.items FOR EACH ROW EXECUTE FUNCTION public.log_item_history();

CREATE TRIGGER set_updated_at_items BEFORE UPDATE ON public.items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_order_archive BEFORE UPDATE ON public.order_archive FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_order_items BEFORE UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_orders BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_updated_at_profiles BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();


