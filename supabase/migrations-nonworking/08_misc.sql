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



SET default_tablespace = '';

SET default_table_access_method = "heap";


RESET ALL;



-- -- Add created_by column after organizations table is created
alter table organizations
add column if not exists created_by uuid references users(id);

-- -- You can also add additional audit fields here if needed
-- alter table organizations
-- add column if not exists last_modified_date timestamptz default now();
-- alter table organizations drop constraint organizations_created_by_fkey;
-- org id : 3924fe74-1c49-442c-a251-1c69345cbd2c
-- user id: ce1edb94-147c-47dd-abb9-509ea263f4ee
-- org_id is missing in the org_members table, so we need to add it. 
-- update the subscritions table to use org_id instead of organization_id. 


-- I had to apply this policiuy on org:  because dashboard was not shwing the org info.
-- -- Enable RLS if not already
-- ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- -- Create policy to allow SELECT
-- CREATE POLICY "Allow select for logged-in users"
--   ON organizations
--   FOR SELECT
--   USING (auth.uid() IS NOT NULL);


-- -- If not already created, run this in Supabase SQL Editor:


-- create table if not exists deals (
--   id uuid primary key default gen_random_uuid(),
--   name text not null,
--   description text,
--   org_id uuid references organizations(id) on delete cascade,
--   created_by uuid references users(id) on delete set null,
--   status text default 'active',
--   created_at timestamp default now()
-- );
-- --Also enable RLS and add this policy:


-- alter table deals enable row level security;
-- create policy "Users can access deals in their org"
-- on deals
-- for select using (
--   exists (
--     select 1 from org_members
--     where org_members.user_id = auth.uid()
--     and org_members.org_id = deals.org_id
--   )
-- );

-- create policy "Users can insert deals into their org"
-- on deals
-- for insert with check (
--   exists (
--     select 1 from org_members
--     where org_members.user_id = auth.uid()
--     and org_members.org_id = deals.org_id
--   )
-- );


-- This is to make mose SaaS freinedly.
-- -- Drop existing deal_stages (only do this if you're ready)
-- drop table if exists deal_stages cascade;

-- -- Create new deal_stages scoped by org_id
-- create table deal_stages (
--   id uuid primary key default gen_random_uuid(),
--   org_id uuid references organizations(id) on delete cascade,
--   name text not null,
--   sort_order int not null default 0,
--   is_final boolean default false,
--   created_at timestamp with time zone default now()
-- );

-- -- Modify deals to reference stage
-- alter table deals
--   add column if not exists current_stage_id uuid references deal_stages(id);

-- -- (Optional) Drop old current_stage if you're ready to stop using it
-- -- alter table deals drop column if exists current_stage;

-- -- Enable RLS
-- alter table deal_stages enable row level security;

-- -- Allow org members to view their stages
-- create policy "Org members can view deal stages"
-- on deal_stages
-- for select
-- using (
--   exists (
--     select 1 from org_members
--     where org_members.user_id = auth.uid()
--     and org_members.org_id = deal_stages.org_id
--   )
-- );

-- -- Allow insert for org admins/brokers
-- create policy "Org admins/brokers can insert stages"
-- on deal_stages
-- for insert
-- with check (
--   exists (
--     select 1 from org_members
--     where org_members.user_id = auth.uid()
--     and org_members.org_id = deal_stages.org_id
--     and org_members.role in ('admin', 'broker')
--   )
-- );
