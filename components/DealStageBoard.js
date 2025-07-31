// components/DealStageBoard.js
import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabaseClient'

const STAGES = [
  'Initial Inquiry',
  'Broker Assigned',
  'Site Visit',
  'Negotiation',
  'Signature Awaiting',
  'Signed',
  'Completed'
]

export default function DealStageBoard({ dealId, deal, setDeal }) {
  const [loading, setLoading] = useState(false)
  const [pendingStatusPrompt, setPendingStatusPrompt] = useState(false)
  const [userId, setUserId] = useState(null)
  const [userEmail, setUserEmail] = useState('')

  useEffect(() => {
    // Fetch current user ID
    const getUser = async () => {
    const result = await supabase.auth.getUser()
    if (result?.data?.user) {
      setUserId(result.data.user.id)
      setUserEmail(result.data.user.email)
    }
      const { data, error } = await supabase.auth.getUser()
      if (data?.user?.id) {
        setUserId(data.user.id)
      }
    }
    getUser()
  }, [])

  const handleDrop = async (e, stage) => {
    e.preventDefault()
    if (!deal || deal.current_stage === stage) return

    if (stage === 'Completed') {
      setDeal({ ...deal, current_stage: 'Completed' })
      setPendingStatusPrompt(true)
    } else {
      await updateStage(stage)
    }
  }

  const updateStage = async (newStage, statusUpdate = null) => {
    setLoading(true)

    const updateData = { current_stage: newStage }
    if (statusUpdate) updateData.status = statusUpdate

    const { data, error } = await supabase
      .from('deals')
      .update(updateData)
      .eq('id', deal.id)
      .select()
      .single()

    if (!error && data) {
      setDeal(data)

      // Insert into audit_log
      let action = statusUpdate ? 'status_updated' : 'stage_changed'
      let description = statusUpdate
        ? `Marked deal as ${statusUpdate}`
        : `Moved to stage: ${newStage}`

        await supabase.from('audit_log').insert({
          deal_id: deal.id,
          deal_name: deal.name,
          user_id: userId,
          user_email: 'shahi.aditya@gmail.com', // ✅ this is needed userEmail
          action,
          description
        })
    } else {
      console.error('Failed to update deal:', error)
    }

    setPendingStatusPrompt(false)
    setLoading(false)
  }

  const allowDrop = (e) => e.preventDefault()

  if (!deal) return <p className="text-sm text-red-500">Deal not loaded</p>

  return (
    <div className="mt-6 bg-white p-4 rounded shadow">
      <h3 className="text-lg font-semibold mb-3">Deal Stages</h3>
      <div className="flex overflow-auto gap-4">
        {STAGES.map((stage) => (
          <div
            key={stage}
            onDrop={(e) => handleDrop(e, stage)}
            onDragOver={allowDrop}
            className="min-w-[280px] bg-gray-50 border rounded-lg shadow-sm p-4 flex flex-col gap-2"
          >
            <h4 className="text-sm font-semibold text-gray-700 mb-2">{stage}</h4>

            {deal?.current_stage === stage && (
              <div
                draggable
                className="cursor-move bg-white rounded-xl border shadow p-4 space-y-2"
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h1 className="text-base font-semibold text-gray-800">{deal.name}</h1>
                    <p className="text-sm text-gray-600">
                      {deal.description || 'No description'}
                    </p>
                  </div>
                  <span className={`px-2 py-0.5 text-xs rounded-full ${
                    deal?.status === 'Closed-Won'
                      ? 'bg-green-100 text-green-800 border-green-300'
                      : deal?.status === 'Closed-Lost'
                      ? 'bg-red-100 text-red-800 border-red-300'
                      : 'bg-blue-100 text-blue-800 border-blue-300'
                  } border`}>
                    {deal.status || 'Open'}
                  </span>
                </div>

                {stage === 'Completed' && pendingStatusPrompt && (
                  <div className="mt-3 text-sm">
                    <label className="block text-gray-600 mb-1">Mark as:</label>
                    <div className="flex gap-2">
                      <button
                        onClick={() => updateStage('Completed', 'Closed-Won')}
                        className="px-3 py-1 bg-green-600 text-white rounded text-xs hover:bg-green-700"
                      >
                        Closed-Won
                      </button>
                      <button
                        onClick={() => updateStage('Completed', 'Closed-Lost')}
                        className="px-3 py-1 bg-red-600 text-white rounded text-xs hover:bg-red-700"
                      >
                        Closed-Lost
                      </button>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}