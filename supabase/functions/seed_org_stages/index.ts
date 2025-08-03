import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { org_id } = await req.json()

  if (!org_id) {
    return new Response(JSON.stringify({ error: 'Missing org_id' }), { status: 400 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const stages = [
    { name: 'Prospecting', sort_order: 1 },
    { name: 'Initial Contact', sort_order: 2 },
    { name: 'NDA Signed', sort_order: 3 },
    { name: 'Information Shared', sort_order: 4 },
    { name: 'Site Visit', sort_order: 5 },
    { name: 'LOI Submitted', sort_order: 6 },
    { name: 'Negotiation', sort_order: 7 },
    { name: 'Under Contract', sort_order: 8 },
    { name: 'Legal Review', sort_order: 9 },
    { name: 'Closed', sort_order: 10, is_final: true },
    { name: 'Lost', sort_order: 11, is_final: true }
  ]

  const { error } = await supabase.from('deal_stages').insert(
    stages.map((s) => ({
      ...s,
      org_id
    }))
  )

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 })
  }

  return new Response(JSON.stringify({ success: true }), { status: 200 })
})
