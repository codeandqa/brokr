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
-- alter table organizations
-- add column if not exists created_by uuid references users(id);

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