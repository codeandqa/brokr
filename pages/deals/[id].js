// pages/deals/[id].js
import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '../../lib/supabaseClient'
import AuthGuard from '../../components/AuthGuard'
import StageTaskList from '../../components/StageTaskList'
import DealStageBoard from '../../components/DealStageBoard'


export default function DealDetail() {
  const router = useRouter()
  const { id } = router.query

  const [deal, setDeal] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    if (!id) return

    const fetchDeal = async () => {
      const { data, error } = await supabase
        .from('deals')
        .select('*')
        .eq('id', id)
        .single()

      if (error) setError('Failed to load deal')
      else setDeal(data)
    }

    fetchDeal()
  }, [id])

  if (!deal && !error) return <div className="p-6 text-gray-600">Loading deal details...</div>
  if (error) return <div className="p-6 text-red-600">{error}</div>

  return (
    <AuthGuard>
      <div className="p-6 space-y-8">
        {/* Deal Summary Card */}
        <div className="bg-white rounded-xl shadow p-6 space-y-4 max-w-5xl mx-auto border">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-2xl font-bold text-gray-800">{deal?.name || 'Untitled Deal'}</h1>
              <p className="text-gray-600 mt-1">{deal?.description || 'No description provided'}</p>
            </div>
            <div className="space-y-2 text-right">
              <div>
                <span className="px-3 py-1 text-sm rounded-full bg-gray-100 text-gray-800 border border-gray-300">
                  Stage: {deal?.current_stage || '—'}
                </span>
              </div>
              <div>
                <span className={`px-3 py-1 text-sm rounded-full ${
                  deal?.status === 'Closed-Won'
                    ? 'bg-green-100 text-green-800 border-green-300'
                    : deal?.status === 'Closed-Lost'
                    ? 'bg-red-100 text-red-800 border-red-300'
                    : 'bg-blue-100 text-blue-800 border-blue-300'
                } border`}>
                  Status: {deal?.status || '—'}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Stage Task Checklist */}
        <div className="bg-white rounded-xl shadow p-6 max-w-5xl mx-auto border">
          <h2 className="text-lg font-semibold mb-4 text-gray-800">Stage Tasks</h2>
          <StageTaskList dealId={id} stage={deal?.current_stage} />
        </div>

        {/* Kanban Drag-and-Drop Stage Tracker */}
        <DealStageBoard dealId={id} deal={deal} setDeal={setDeal} />
      </div>
    </AuthGuard>
  )
}