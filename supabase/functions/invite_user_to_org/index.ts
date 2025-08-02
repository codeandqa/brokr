// supabase/functions/invite_user_to_org.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const body = await req.json()
  const { email, role, org_id } = body

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // 1. Check if user already exists
  const { data: existingUser, error: lookupError } = await supabase
    .from('users')
    .select('id')
    .eq('email', email)
    .maybeSingle()

  if (lookupError) {
    return new Response(JSON.stringify({ error: lookupError.message }), { status: 400 })
  }

  let userId = existingUser?.id

  // 2. If not exist, create user record (soft create)
  if (!userId) {
    const { data: newUser, error: insertError } = await supabase
      .from('users')
      .insert({ email })
      .select('id')
      .single()

    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), { status: 400 })
    }

    userId = newUser.id
  }

  // 3. Add to org_members
  const { error: memberError } = await supabase
    .from('org_members')
    .insert({
      user_id: userId,
      org_id,
      role,
    })

  if (memberError) {
    return new Response(JSON.stringify({ error: memberError.message }), { status: 400 })
  }

  return new Response(JSON.stringify({ success: true }), { status: 200 })
})
