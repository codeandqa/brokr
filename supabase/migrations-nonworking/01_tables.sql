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


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid",
    "plan" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "trial_ends_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


ALTER TABLE ONLY "public"."app_config"
ALTER TABLE ONLY "public"."audit_log"
ALTER TABLE ONLY "public"."audit_logs"
ALTER TABLE ONLY "public"."deal_stages"
ALTER TABLE ONLY "public"."deals"
ALTER TABLE ONLY "public"."default_stage_tasks"
ALTER TABLE ONLY "public"."org_members"
ALTER TABLE ONLY "public"."organizations"
ALTER TABLE ONLY "public"."stage_tasks"
ALTER TABLE ONLY "public"."subscriptions"
ALTER TABLE ONLY "public"."users"
ALTER TABLE ONLY "public"."audit_log"
ALTER TABLE ONLY "public"."audit_logs"
ALTER TABLE ONLY "public"."audit_logs"
ALTER TABLE ONLY "public"."deal_stages"
ALTER TABLE ONLY "public"."deals"
ALTER TABLE ONLY "public"."deals"
ALTER TABLE ONLY "public"."deals"
ALTER TABLE ONLY "public"."org_members"
ALTER TABLE ONLY "public"."org_members"
ALTER TABLE ONLY "public"."stage_tasks"
ALTER TABLE ONLY "public"."stage_tasks"
ALTER TABLE ONLY "public"."stage_tasks"
ALTER TABLE ONLY "public"."subscriptions"
ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."deal_stages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."org_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stage_tasks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


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









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";

























