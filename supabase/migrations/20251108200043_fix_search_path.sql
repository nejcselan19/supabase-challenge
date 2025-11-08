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
  v_first_name := coalesce(new.raw_user_meta_data->>'first_name', 'Unknown');
  v_last_name  := coalesce(new.raw_user_meta_data->>'last_name', 'Unknown');

  insert into public.profiles (id, first_name, last_name)
  values (new.id, v_first_name, v_last_name)
  on conflict (id) do nothing;

  return new;
end;
$function$
;


