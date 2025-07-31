DROP TRIGGER IF EXISTS "trg_copy_stage_tasks" ON "public"."deals";

CREATE TRIGGER "trg_copy_stage_tasks"
AFTER UPDATE
ON "public"."deals"
FOR EACH ROW
WHEN ((old.status IS DISTINCT FROM new.status))
EXECUTE FUNCTION "public"."copy_stage_tasks_on_stage_change"();



DROP TRIGGER IF EXISTS "trg_status_change" ON "public"."deals";

CREATE TRIGGER "trg_status_change"
BEFORE UPDATE
ON "public"."deals"
FOR EACH ROW
EXECUTE FUNCTION "public"."trg_log_deal_status_stage_change"();