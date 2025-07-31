// supabase/functions/trial-cleanup/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.6'

serve(async () => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { data: expired, error } = await supabase
    .from('subscriptions')
    .select('id, organization_id, plan, trial_ends_at')
    .eq('plan', 'trialing')
    .lt('trial_ends_at', new Date().toISOString())

  if (error) {
    console.error('[TrialCleanup] Fetch error:', error)
    return new Response(JSON.stringify({ error: 'Fetch failed' }), { status: 500 })
  }

  const expiredIds = (expired || []).map(sub => sub.id)

  if (expiredIds.length > 0) {
    const { error: updateError } = await supabase
      .from('subscriptions')
      .update({ status: 'canceled' })
      .in('id', expiredIds)

    if (updateError) {
      console.error('[TrialCleanup] Update error:', updateError)
      return new Response(JSON.stringify({ error: 'Update failed' }), { status: 500 })
    }
  }

  return new Response(JSON.stringify({ success: true, updated: expiredIds.length }))
})
