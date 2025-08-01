CREATE OR REPLACE FUNCTION "public"."auto_add_stage_tasks"("p_deal_id" "uuid", "p_stage_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into stage_tasks (deal_id, stage_id, name)
  select p_deal_id, p_stage_id, name from (
    values
      ('Schedule walk-through'),
      ('Share site plan with client'),
      ('Log broker notes')
  ) as defaults(name);
end;
$$;


ALTER FUNCTION "public"."auto_add_stage_tasks"("p_deal_id" "uuid", "p_stage_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."copy_stage_tasks_on_stage_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  delete from stage_tasks where deal_id = new.id;

  insert into stage_tasks (deal_id, stage, task_label, sort_order)
  select new.id, dst.stage_name, dst.task_label, dst.sort_order
  from default_stage_tasks dst
  where dst.stage_name = new.status;

  return new;
end;
$$;


ALTER FUNCTION "public"."copy_stage_tasks_on_stage_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_org_users"() RETURNS TABLE("member_id" "uuid", "user_id" "uuid", "email" "text", "full_name" "text", "role" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  select
    om.id as member_id,
    u.id as user_id,
    u.email,
    u.full_name,
    om.role
  from org_members om
  join users u on u.id = om.user_id
  where om.org_id in (
    select org_id from org_members where user_id = auth.uid()
  );
$$;


ALTER FUNCTION "public"."get_org_users"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_action"("p_user_id" "uuid", "p_org_id" "uuid", "p_action" "text", "p_target_type" "text", "p_target_id" "uuid", "p_details" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  insert into audit_logs (user_id, org_id, action, target_type, target_id, details)
  values (p_user_id, p_org_id, p_action, p_target_type, p_target_id, p_details);
end;
$$;


ALTER FUNCTION "public"."log_action"("p_user_id" "uuid", "p_org_id" "uuid", "p_action" "text", "p_target_type" "text", "p_target_id" "uuid", "p_details" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_log_deal_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  actor_id uuid := auth.uid();
begin
  if new.status is distinct from old.status then
    perform log_action(
      actor_id,
      new.org_id,
      'status_changed',
      'deal',
      new.id,
      jsonb_build_object('from', old.status, 'to', new.status)
    );
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."trg_log_deal_status_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_log_deal_status_stage_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  actor_id uuid := auth.uid();
  from_stage text;
  to_stage text;
begin
  -- Status change logging
  if new.status is distinct from old.status then
    perform log_action(
      actor_id,
      new.org_id,
      'status_changed',
      'deal',
      new.id,
      jsonb_build_object('from', old.status, 'to', new.status)
    );
  end if;

  -- Stage change logging
  if new.current_stage_id is distinct from old.current_stage_id then
    select name into from_stage from deal_stages where id = old.current_stage_id;
    select name into to_stage from deal_stages where id = new.current_stage_id;

    perform log_action(
      actor_id,
      new.org_id,
      'stage_changed',
      'deal',
      new.id,
      jsonb_build_object('from', from_stage, 'to', to_stage)
    );
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."trg_log_deal_status_stage_change"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."auto_add_stage_tasks"("p_deal_id" "uuid", "p_stage_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."auto_add_stage_tasks"("p_deal_id" "uuid", "p_stage_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_add_stage_tasks"("p_deal_id" "uuid", "p_stage_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."copy_stage_tasks_on_stage_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."copy_stage_tasks_on_stage_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."copy_stage_tasks_on_stage_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_org_users"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_org_users"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_org_users"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_action"("p_user_id" "uuid", "p_org_id" "uuid", "p_action" "text", "p_target_type" "text", "p_target_id" "uuid", "p_details" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_action"("p_user_id" "uuid", "p_org_id" "uuid", "p_action" "text", "p_target_type" "text", "p_target_id" "uuid", "p_details" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_action"("p_user_id" "uuid", "p_org_id" "uuid", "p_action" "text", "p_target_type" "text", "p_target_id" "uuid", "p_details" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_log_deal_status_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_log_deal_status_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_log_deal_status_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_log_deal_status_stage_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_log_deal_status_stage_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_log_deal_status_stage_change"() TO "service_role";


















ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






