import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

console.log(`🟢 Edge Function 'create-trial-org' running`)

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    // Handle preflight CORS
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
    })
  }

  try {
    const { orgName, user_id, email } = await req.json()

    console.log('📨 Received orgName:', orgName)
    console.log('👤 user_id:', user_id)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    let response = await fetch(`${supabaseUrl}/rest/v1/organizations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        name: orgName,
        plan: 'trial',
        status: 'active',
        created_by: user_id
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ Org creation failed:', errorText)
      return new Response(JSON.stringify({ error: 'Failed to create org: ' + errorText }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }

    const org = await response.json()
    console.log('✅ Org created:', org)


    ///sdfsdfsd
    console.log('📨 Creating user with ID:', user_id, 'and email:', email)
    response = await fetch(`${supabaseUrl}/rest/v1/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        
        id: user_id,
        email: email,
        role: 'admin',
        org_id: org.id
      })
    })
    console.log('📨 User creation response status:', response.status)
    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ user creation failed:', errorText)
      return new Response(JSON.stringify({ error: 'Failed to create user: ' + errorText }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }

    const user = await response.json()
    console.log('✅ User added:', user)

    ///sdfsdfsdf

console.log('📨 Creating user with ID:', user_id, 'and org:', org.id)
    response = await fetch(`${supabaseUrl}/rest/v1/org_members`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        
        user_id: user_id,
        org_id: org.id,
        role: 'admin'
      })
    })
    console.log('📨 User creation response status:', response.status)
    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ user creation failed:', errorText)
      return new Response(JSON.stringify({ error: 'Failed to create user: ' + errorText }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }


    
    return new Response(JSON.stringify({ message: 'Trial org created successfully' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  } catch (e) {
    console.error('❌ Unexpected error:', e)
    return new Response(JSON.stringify({ error: 'Unexpected server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  }
})
