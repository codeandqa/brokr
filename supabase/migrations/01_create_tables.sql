-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.app_config (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  key text,
  value text,
  CONSTRAINT app_config_pkey PRIMARY KEY (id)
);
CREATE TABLE public.audit_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  deal_id uuid,
  action text,
  description text,
  created_at timestamp without time zone DEFAULT now(),
  deal_name text,
  user_id uuid,
  user_email text,
  CONSTRAINT audit_log_pkey PRIMARY KEY (id),
  CONSTRAINT audit_log_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES public.deals(id)
);
CREATE TABLE public.audit_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  org_id uuid,
  action text NOT NULL,
  target_type text,
  target_id uuid,
  details jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT audit_logs_pkey PRIMARY KEY (id),
  CONSTRAINT audit_logs_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.deal_stages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  deal_id uuid,
  name text NOT NULL,
  sort_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT deal_stages_pkey PRIMARY KEY (id),
  CONSTRAINT deal_stages_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES public.deals(id)
);
CREATE TABLE public.deals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid,
  created_by uuid,
  name text NOT NULL,
  description text,
  status text DEFAULT 'open'::text CHECK (status = ANY (ARRAY['Open'::text, 'Closed-Won'::text, 'Closed-Lost'::text])),
  created_at timestamp with time zone DEFAULT now(),
  current_stage_id uuid,
  current_stage text CHECK (current_stage = ANY (ARRAY['Initial Inquiry'::text, 'Broker Assigned'::text, 'Site Visit'::text, 'Negotiation'::text, 'Signature Awaiting'::text, 'Signed'::text, 'Completed'::text])),
  CONSTRAINT deals_pkey PRIMARY KEY (id),
  CONSTRAINT deals_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT deals_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT deals_current_stage_id_fkey FOREIGN KEY (current_stage_id) REFERENCES public.deal_stages(id)
);
CREATE TABLE public.default_stage_tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  stage_name text NOT NULL,
  task_label text NOT NULL,
  sort_order integer DEFAULT 0,
  CONSTRAINT default_stage_tasks_pkey PRIMARY KEY (id)
);
CREATE TABLE public.org_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  org_id uuid,
  role text NOT NULL CHECK (role = ANY (ARRAY['super_admin'::text, 'admin'::text, 'broker'::text, 'legal'::text, 'viewer'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT org_members_pkey PRIMARY KEY (id),
  CONSTRAINT org_members_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id),
  CONSTRAINT org_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.organizations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  region text DEFAULT 'US'::text,
  logo_url text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT organizations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.stage_tasks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  deal_id uuid,
  stage_id uuid,
  completed boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  stage text,
  task_label text,
  sort_order integer DEFAULT 0,
  is_completed boolean DEFAULT false,
  assigned_to uuid,
  due_date date,
  CONSTRAINT stage_tasks_pkey PRIMARY KEY (id),
  CONSTRAINT stage_tasks_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES public.deals(id),
  CONSTRAINT stage_tasks_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.deal_stages(id),
  CONSTRAINT stage_tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id)
);
CREATE TABLE public.subscriptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid,
  plan text NOT NULL CHECK (plan = ANY (ARRAY['free'::text, 'pro'::text, 'enterprise'::text])),
  status text NOT NULL DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'trialing'::text, 'past_due'::text, 'canceled'::text])),
  trial_ends_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subscriptions_pkey PRIMARY KEY (id),
  CONSTRAINT subscriptions_organization_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  full_name text,
  email text,
  created_at timestamp with time zone DEFAULT now(),
  role text DEFAULT 'broker'::text CHECK (role = ANY (ARRAY['broker'::text, 'admin'::text, 'super_admin'::text])),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);