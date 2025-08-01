    CONSTRAINT "deals_current_stage_check" CHECK (("current_stage" = ANY (ARRAY['Initial Inquiry'::"text", 'Broker Assigned'::"text", 'Site Visit'::"text", 'Negotiation'::"text", 'Signature Awaiting'::"text", 'Signed'::"text", 'Completed'::"text"]))),
    CONSTRAINT "deals_status_check" CHECK (("status" = ANY (ARRAY['Open'::"text", 'Closed-Won'::"text", 'Closed-Lost'::"text"])))
);


    CONSTRAINT "org_members_role_check" CHECK (("role" = ANY (ARRAY['super_admin'::"text", 'admin'::"text", 'broker'::"text", 'legal'::"text", 'viewer'::"text"])))
);


    CONSTRAINT "users_role_check" CHECK (("role" = ANY (ARRAY['broker'::"text", 'admin'::"text", 'super_admin'::"text"])))
);


    CONSTRAINT "subscriptions_plan_check" CHECK (("plan" = ANY (ARRAY['free'::"text", 'pro'::"text", 'enterprise'::"text"]))),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'trialing'::"text", 'past_due'::"text", 'canceled'::"text"])))
);


    ADD CONSTRAINT "app_config_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "deal_stages_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "deals_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "default_stage_tasks_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "org_members_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "stage_tasks_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



    ADD CONSTRAINT "audit_log_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals"("id") ON DELETE CASCADE;



    ADD CONSTRAINT "audit_logs_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



    ADD CONSTRAINT "deal_stages_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals"("id") ON DELETE CASCADE;



    ADD CONSTRAINT "deals_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



    ADD CONSTRAINT "deals_current_stage_id_fkey" FOREIGN KEY ("current_stage_id") REFERENCES "public"."deal_stages"("id");



    ADD CONSTRAINT "deals_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



    ADD CONSTRAINT "org_members_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



    ADD CONSTRAINT "org_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



    ADD CONSTRAINT "stage_tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id");



    ADD CONSTRAINT "stage_tasks_deal_id_fkey" FOREIGN KEY ("deal_id") REFERENCES "public"."deals"("id") ON DELETE CASCADE;



    ADD CONSTRAINT "stage_tasks_stage_id_fkey" FOREIGN KEY ("stage_id") REFERENCES "public"."deal_stages"("id") ON DELETE CASCADE;



    ADD CONSTRAINT "subscriptions_organization_id_fkey" FOREIGN KEY ("org_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



CREATE POLICY "Allow insert if user in org" ON "public"."stage_tasks" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."deals"
     JOIN "public"."org_members" ON (("deals"."org_id" = "org_members"."org_id")))
  WHERE (("deals"."id" = "stage_tasks"."deal_id") AND ("org_members"."user_id" = "auth"."uid"())))));



CREATE POLICY "Allow public insert for org signup" ON "public"."organizations" FOR INSERT WITH CHECK (true);



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



CREATE POLICY "Prevent insert if trial expired (stage_tasks)" ON "public"."stage_tasks" FOR INSERT WITH CHECK (( SELECT
        CASE
            WHEN (("s"."plan" = 'trialing'::"text") AND ("s"."trial_ends_at" < "now"())) THEN false
            ELSE true
        END AS "case"
   FROM ("public"."deals" "d"
     JOIN "public"."subscriptions" "s" ON (("s"."org_id" = "d"."org_id")))
  WHERE ("d"."id" = "stage_tasks"."deal_id")));



CREATE POLICY "Users can insert/update themselves" ON "public"."users" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Prevent insert if trial expired (stage_tasks)" ON "public"."stage_tasks" FOR INSERT WITH CHECK (( SELECT
        CASE
            WHEN (("s"."plan" = 'trialing'::"text") AND ("s"."trial_ends_at" < "now"())) THEN false
            ELSE true
        END AS "case"
   FROM ("public"."deals" "d"
     JOIN "public"."subscriptions" "s" ON (("s"."org_id" = "d"."org_id")))
  WHERE ("d"."id" = "stage_tasks"."deal_id")));
CREATE POLICY "Prevent insert if trial expired (stage_tasks)" ON "public"."stage_tasks" FOR INSERT WITH CHECK (( SELECT
        CASE
            WHEN (("s"."plan" = 'trialing'::"text") AND ("s"."trial_ends_at" < "now"())) THEN false
            ELSE true
        END AS "case"
    FROM ("public"."deals" "d"
      JOIN "public"."subscriptions" "s" ON (("s"."org_id" = "d"."org_id")))
  WHERE ("d"."id" = "stage_tasks"."deal_id")));

