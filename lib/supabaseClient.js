// lib/supabaseClient.js
import { createClient } from '@supabase/supabase-js'

// This will be used across the app to make Supabase API calls
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)


