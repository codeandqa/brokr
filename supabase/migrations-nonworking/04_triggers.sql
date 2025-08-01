CREATE OR REPLACE TRIGGER "trg_copy_stage_tasks" AFTER UPDATE OF "status" ON "public"."deals" FOR EACH ROW WHEN (("old"."status" IS DISTINCT FROM "new"."status")) EXECUTE FUNCTION "public"."copy_stage_tasks_on_stage_change"();



CREATE OR REPLACE TRIGGER "trg_status_change" BEFORE UPDATE ON "public"."deals" FOR EACH ROW EXECUTE FUNCTION "public"."trg_log_deal_status_stage_change"();



