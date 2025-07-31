// supabase/functions/send-stage-change-notification/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.6'

serve(async (req) => {
  const { deal_id, new_stage, status, actor_email } = await req.json()

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  console.log('[Debug] Function triggered')
  console.log('[Debug] Using deal_id:', deal_id)

  const mailerKey = "mlsn.1093aec86842bcd6e7ba3f14384efac7e0769258ae0a1627258fb75cb8137c26" // Replace before deploying

  const { data: deal, error: dealError } = await supabase
    .from('deals')
    .select('name, organization_id')
    .eq('id', deal_id)
    .single()

  console.log('[Debug] dealError:', dealError)
  console.log('[Debug] deal:', deal)

  if (dealError || !deal) {
    return new Response(JSON.stringify({ error: 'Deal not found' }), { status: 400 })
  }

  const recipients = [{ email: 'shahi.aditya@gmail.com' }]

  try {
    const mailersendRes = await fetch('https://api.mailersend.com/v1/email', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${mailerKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: { email: 'shahi.aditya@gmail.com', name: 'Brokr Test' },
        to: recipients,
        subject: `📢 Deal stage updated: ${deal.name}`,
        text: `The deal "${deal.name}" has moved to stage "${new_stage}".\n\nStatus: ${status || 'N/A'}\nChanged by: ${actor_email}`
      })
    })

    const resultText = await mailersendRes.text()
    console.log('[MailerSend STATUS]', mailersendRes.status)
    console.log('[MailerSend BODY]', resultText)

    if (!mailersendRes.ok) {
      return new Response(JSON.stringify({ error: 'MailerSend failed', details: resultText }), { status: 500 })
    }

    return new Response(JSON.stringify({ success: true }))
  } catch (err) {
    console.log('[MailerSend CATCH ERROR]', err)
    return new Response(JSON.stringify({ error: 'MailerSend exception', message: String(err) }), { status: 500 })
  }
})
