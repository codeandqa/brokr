SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






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

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."app_config" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "key" "text",
    "value" "text"
);


ALTER TABLE "public"."app_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deal_id" "uuid",
    "action" "text",
    "description" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "deal_name" "text",
    "user_id" "uuid",
    "user_email" "text"
);


ALTER TABLE "public"."audit_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "org_id" "uuid",
    "action" "text" NOT NULL,
    "target_type" "text",
    "target_id" "uuid",
    "details" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."deal_stages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deal_id" "uuid",
    "name" "text" NOT NULL,
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."deal_stages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."deals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid",
    "created_by" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'open'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "current_stage_id" "uuid",
    "current_stage" "text",
    CONSTRAINT "deals_current_stage_check" CHECK (("current_stage" = ANY (ARRAY['Initial Inquiry'::"text", 'Broker Assigned'::"text", 'Site Visit'::"text", 'Negotiation'::"text", 'Signature Awaiting'::"text", 'Signed'::"text", 'Completed'::"text"]))),
    CONSTRAINT "deals_status_check" CHECK (("status" = ANY (ARRAY['Open'::"text", 'Closed-Won'::"text", 'Closed-Lost'::"text"])))
);


ALTER TABLE "public"."deals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."default_stage_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "stage_name" "text" NOT NULL,
    "task_label" "text" NOT NULL,
    "sort_order" integer DEFAULT 0
);


ALTER TABLE "public"."default_stage_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."org_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "org_id" "uuid",
    "role" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "org_members_role_check" CHECK (("role" = ANY (ARRAY['super_admin'::"text", 'admin'::"text", 'broker'::"text", 'legal'::"text", 'viewer'::"text"])))
);


ALTER TABLE "public"."org_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."organizations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "region" "text" DEFAULT 'US'::"text",
    "logo_url" "text",
    "plan" "text" DEFAULT 'trial'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);



ALTER TABLE "public"."organizations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stage_tasks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deal_id" "uuid",
    "stage_id" "uuid",
    "completed" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "stage" "text",
    "task_label" "text",
    "sort_order" integer DEFAULT 0,
    "is_completed" boolean DEFAULT false,
    "assigned_to" "uuid",
    "due_date" "date"
);


ALTER TABLE "public"."stage_tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" "text",
    "email" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "role" "text" DEFAULT 'broker'::"text",
    CONSTRAINT "users_role_check" CHECK (("role" = ANY (ARRAY['broker'::"text", 'admin'::"text", 'super_admin'::"text"])))
);


ALTER TABLE "public"."users" OWNER TO "postgres";

CREATE OR REPLACE VIEW "public"."stage_tasks_with_user" AS
 SELECT "st"."id",
    "st"."deal_id",
    "st"."stage_id",
    "st"."completed",
    "st"."created_at",
    "st"."stage",
    "st"."task_label",
    "st"."sort_order",
    "st"."is_completed",
    "st"."assigned_to",
    "st"."due_date",
    "u"."email" AS "assigned_email"
   FROM ("public"."stage_tasks" "st"
     LEFT JOIN "public"."users" "u" ON (("st"."assigned_to" = "u"."id")));


ALTER VIEW "public"."stage_tasks_with_user" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid",
    "plan" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "trial_ends_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "subscriptions_plan_check" CHECK (("plan" = ANY (ARRAY['free'::"text", 'pro'::"text", 'enterprise'::"text"]))),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'trialing'::"text", 'past_due'::"text", 'canceled'::"text"])))
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


ALTER TABLE ONLY "public"."app_config"
    ADD CONSTRAINT "app_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."deal_stages"
    ADD CONSTRAINT "deal_stages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."deals"
    ADD CONSTRAINT "deals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."default_stage_tasks"
    ADD CONSTRAINT "default_stage_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."org_members"
    ADD CONSTRAINT "org_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."stage_tasks"
    ADD CONSTRAINT "stage_tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE OR REPLACE TRIGGER "trg_copy_stage_tasks" AFTER UPDATE OF "status" ON "public"."deals" FOR EACH ROW WHEN (("old"."status" IS DISTINCT FROM "new"."status")) EXECUTE FUNCTION "public"."copy_stage_tasks_on_stage_change"();



CREATE OR REPLACE TRIGGER "trg_status_change" BEFORE UPDATE ON "public"."deals" FOR EACH ROW EXECUTE FUNCTION "public"."trg_log_deal_status_stage_change"();


ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."deal_stages"
    ADD CONSTRAINT "deal_stages_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."deals"
    ADD CONSTRAINT "deals_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."deals"
    ADD CONSTRAINT "deals_current_stage_id_fkey" FOREIGN KEY ("current_stage_id") REFERENCES "public"."deal_stages"("id");



ALTER TABLE ONLY "public"."deals"
    ADD CONSTRAINT "deals_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."org_members"
    ADD CONSTRAINT "org_members_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."org_members"
    ADD CONSTRAINT "org_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;






ALTER TABLE ONLY "public"."stage_tasks"
    ADD CONSTRAINT "stage_tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id");




ALTER TABLE ONLY "public"."stage_tasks"
    ADD CONSTRAINT "stage_tasks_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stage_tasks"
    ADD CONSTRAINT "stage_tasks_stage_id_fkey" FOREIGN KEY ("stage_id") REFERENCES "public"."deal_stages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_organization_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



CREATE POLICY "Allow insert if user in org" ON "public"."stage_tasks" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."deals"
     JOIN "public"."org_members" ON (("deals"."org_id" = "org_members"."org_id")))
  WHERE (("deals"."id" = "stage_tasks"."deal_id") AND ("org_members"."user_id" = "auth"."uid"())))));



CREATE POLICY "Allow public insert for org signup" ON "public"."organizations" FOR INSERT WITH CHECK (true);



CREATE POLICY "Allow update by creator" ON "public"."deals" FOR UPDATE USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Only allow user insert if limit not exceeded" ON "public"."org_members" FOR INSERT WITH CHECK ((( SELECT "count"(*) AS "count"
   FROM "public"."org_members" "om"
  WHERE ("om"."org_id" = "org_members"."org_id")) <
CASE
    WHEN (( SELECT "s"."plan"
       FROM "public"."subscriptions" "s"
      WHERE ("s"."org_id" = "org_members"."org_id")) = 'free'::"text") THEN 3
    ELSE 9999
END));



CREATE POLICY "Org members can insert deals" ON "public"."deals" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."org_members"
  WHERE (("org_members"."user_id" = "auth"."uid"()) AND ("org_members"."org_id" = "deals"."org_id") AND ("org_members"."role" = ANY (ARRAY['super_admin'::"text", 'admin'::"text", 'broker'::"text"]))))));



CREATE POLICY "Org members can read their own subscription" ON "public"."subscriptions" FOR SELECT USING (("auth"."uid"() IN ( SELECT "org_members"."user_id"
   FROM "public"."org_members"
  WHERE ("org_members"."org_id" = "subscriptions"."org_id"))));



CREATE POLICY "Org members can see their orgs" ON "public"."org_members" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Org members can select deals for RLS" ON "public"."deals" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."org_members"
  WHERE (("org_members"."user_id" = "auth"."uid"()) AND ("org_members"."org_id" = "deals"."org_id")))));



CREATE POLICY "Org members can update tasks" ON "public"."stage_tasks" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."org_members"
  WHERE (("org_members"."user_id" = "auth"."uid"()) AND ("org_members"."org_id" = ( SELECT "deals"."org_id"
           FROM "public"."deals"
          WHERE ("deals"."id" = "stage_tasks"."deal_id")))))));



CREATE POLICY "Org members can view audit logs" ON "public"."audit_logs" FOR SELECT USING ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."org_members"
  WHERE (("org_members"."org_id" = "audit_logs"."org_id") AND ("org_members"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Org members can view tasks" ON "public"."stage_tasks" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."org_members"
  WHERE (("org_members"."user_id" = "auth"."uid"()) AND ("org_members"."org_id" = ( SELECT "deals"."org_id"
           FROM "public"."deals"
          WHERE ("deals"."id" = "stage_tasks"."deal_id")))))));



CREATE POLICY "Prevent insert if trial expired (stage_tasks)" ON "public"."stage_tasks" FOR INSERT WITH CHECK (( SELECT
        CASE
            WHEN (("s"."plan" = 'trialing'::"text") AND ("s"."trial_ends_at" < "now"())) THEN false
            ELSE true
        END AS "case"
   FROM ("public"."deals" "d"
     JOIN "public"."subscriptions" "s" ON (("s"."org_id" = "d"."org_id")))
  WHERE ("d"."id" = "stage_tasks"."deal_id")));



CREATE POLICY "Update own deals" ON "public"."deals" FOR SELECT USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Users can access org deals" ON "public"."deals" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."org_members"
  WHERE (("org_members"."user_id" = "auth"."uid"()) AND ("org_members"."org_id" = "deals"."org_id")))));



CREATE POLICY "Users can insert/update themselves" ON "public"."users" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can update themselves" ON "public"."users" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view themselves" ON "public"."users" FOR SELECT USING (("auth"."uid"() = "id"));



ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."deal_stages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."org_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stage_tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































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


















GRANT ALL ON TABLE "public"."app_config" TO "anon";
GRANT ALL ON TABLE "public"."app_config" TO "authenticated";
GRANT ALL ON TABLE "public"."app_config" TO "service_role";



GRANT ALL ON TABLE "public"."audit_log" TO "anon";
GRANT ALL ON TABLE "public"."audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_log" TO "service_role";



GRANT ALL ON TABLE "public"."audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."deal_stages" TO "anon";
GRANT ALL ON TABLE "public"."deal_stages" TO "authenticated";
GRANT ALL ON TABLE "public"."deal_stages" TO "service_role";



GRANT ALL ON TABLE "public"."deals" TO "anon";
GRANT ALL ON TABLE "public"."deals" TO "authenticated";
GRANT ALL ON TABLE "public"."deals" TO "service_role";



GRANT ALL ON TABLE "public"."default_stage_tasks" TO "anon";
GRANT ALL ON TABLE "public"."default_stage_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."default_stage_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."org_members" TO "anon";
GRANT ALL ON TABLE "public"."org_members" TO "authenticated";
GRANT ALL ON TABLE "public"."org_members" TO "service_role";



GRANT ALL ON TABLE "public"."organizations" TO "anon";
GRANT ALL ON TABLE "public"."organizations" TO "authenticated";
GRANT ALL ON TABLE "public"."organizations" TO "service_role";



GRANT ALL ON TABLE "public"."stage_tasks" TO "anon";
GRANT ALL ON TABLE "public"."stage_tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."stage_tasks" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."stage_tasks_with_user" TO "anon";
GRANT ALL ON TABLE "public"."stage_tasks_with_user" TO "authenticated";
GRANT ALL ON TABLE "public"."stage_tasks_with_user" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";





















-- Add created_by column after organizations table is created
-- alter table organizations
-- add column if not exists created_by uuid references users(id);

-- You can also add additional audit fields here if needed
-- alter table organizations
-- add column if not exists last_modified_date timestamptz default now();
-- alter table organizations
-- add column if not exists status text default 'trial';


RESET ALL;
-- CREATE POLICY "Prevent insert if trial expired (stage_tasks)" ON "public"."stage_tasks" FOR INSERT WITH CHECK (( SELECT
--         CASE
--             WHEN (("s"."plan" = 'trialing'::"text") AND ("s"."trial_ends_at" < "now"())) THEN false
--             ELSE true
--         END AS "case"
--    FROM ("public"."deals" "d"
--      JOIN "public"."subscriptions" "s" ON (("s"."org_id" = "d"."org_id")))
--   WHERE ("d"."id" = "stage_tasks"."deal_id")));
-- CREATE POLICY "Prevent insert if trial expired (stage_tasks)" ON "public"."stage_tasks" FOR INSERT WITH CHECK (( SELECT
--         CASE
--             WHEN (("s"."plan" = 'trialing'::"text") AND ("s"."trial_ends_at" < "now"())) THEN false
--             ELSE true
--         END AS "case"
--     FROM ("public"."deals" "d"
--       JOIN "public"."subscriptions" "s" ON (("s"."org_id" = "d"."org_id")))
--   WHERE ("d"."id" = "stage_tasks"."deal_id")));

