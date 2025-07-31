#!/bin/bash

# Exit immediately on error
set -e

# Configure Supabase local DB URL
DB_URL="postgres://postgres:postgres@localhost:54322/postgres"

# Log the starting point
echo "🔄 Starting Supabase DB initialization..."

# Apply schema files
psql "$DB_URL" -f ./supabase/sql/01_create_tables.sql
echo "✅ Tables created."

psql "$DB_URL" -f ./supabase/sql/02_rls_policies.sql
echo "✅ RLS policies applied."

psql "$DB_URL" -f ./supabase/sql/03_seed_data.sql
echo "✅ Seed data inserted."

echo "🎉 Supabase DB initialized successfully!"
