CREATE POLICY "Allow update by creator" ON "public"."deals" FOR UPDATE USING (("auth"."uid"() = "created_by"));



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



CREATE POLICY "Update own deals" ON "public"."deals" FOR SELECT USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Users can access org deals" ON "public"."deals" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."org_members"
  WHERE (("org_members"."user_id" = "auth"."uid"()) AND ("org_members"."org_id" = "deals"."org_id")))));



CREATE POLICY "Users can update themselves" ON "public"."users" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view themselves" ON "public"."users" FOR SELECT USING (("auth"."uid"() = "id"));



