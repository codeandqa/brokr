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
