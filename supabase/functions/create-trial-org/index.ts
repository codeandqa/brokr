// supabase/functions/create-trial-org/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.6'

serve(async (req) => {
  try {
    const body = await req.json()
    console.log('[DEBUG] Raw Body:', body)

    const { org_name, user_id, user_email } = body

    if (!org_name || !user_id || !user_email) {
      console.error('[DEBUG] Missing field(s):', { org_name, user_id, user_email })
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log('[DEBUG] Creating organization:', org_name)
    const { data: org, error: orgError } = await supabase
      .from('organizations')
      .insert({ name: org_name })
      .select()
      .single()

    if (orgError || !org) {
      console.error('[DEBUG] Org insert error:', orgError)
      return new Response(JSON.stringify({ error: 'Failed to create organization' }), { status: 500 })
    }

    console.log('[DEBUG] Inserting user:', user_email)
    const { error: userError } = await supabase.from('users').insert({
      id: user_id,
      email: user_email,
      role: 'admin'
    })
    if (userError) {
      console.error('[DEBUG] User insert error:', userError)
    }

    console.log('[DEBUG] Linking user to org')
    const { error: memberError } = await supabase.from('org_members').insert({
      user_id,
      org_id: org.id,
      role: 'admin'
    })
    if (memberError) {
      console.error('[DEBUG] Org member insert error:', memberError)
    }

    console.log('[DEBUG] Creating trial subscription')
    const trialEnd = new Date()
    trialEnd.setDate(trialEnd.getDate() + 30)

    const { error: subError } = await supabase.from('subscriptions').insert({
      org_id: org.id,
      plan: 'trial',
      status: 'active',
      trial_ends_at: trialEnd.toISOString()
    })

    if (subError) {
      console.error('[DEBUG] Subscription insert error:', subError)
    }

    return new Response(JSON.stringify({ success: true, org_id: org.id }))
  } catch (err) {
    console.error('[DEBUG] Unhandled error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 })
  }
})
