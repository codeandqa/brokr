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


