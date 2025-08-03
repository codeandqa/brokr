import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { useSession, useSupabaseClient } from '@supabase/auth-helpers-react'
import AuthGuard from '../../components/AuthGuard'
import { Plus } from 'lucide-react'

export default function DealsPage() {
  const session = useSession()
  const supabase = useSupabaseClient()
  const router = useRouter()

  const [deals, setDeals] = useState([])
  const [orgId, setOrgId] = useState(null)
  const [loading, setLoading] = useState(true)

  const [showModal, setShowModal] = useState(false)
  const [dealName, setDealName] = useState('')
  const [dealDescription, setDealDescription] = useState('')

  useEffect(() => {
    if (session?.user?.id) {
      loadDeals()
    }
  }, [session])

  // ✅ Get org_id and fetch deals
  async function loadDeals() {
    setLoading(true)

    const { data: orgMember, error: orgErr } = await supabase
      .from('org_members')
      .select('org_id')
      .eq('user_id', session.user.id)
      .single()

    if (orgErr || !orgMember) {
      console.error('Could not get org_id:', orgErr)
      setLoading(false)
      return
    }

    setOrgId(orgMember.org_id)

    const { data, error } = await supabase
      .from('deals')
      .select('*')
      .eq('org_id', orgMember.org_id)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Failed to fetch deals:', error)
    } else {
      setDeals(data)
    }

    setLoading(false)
  }

  // ✅ Create a new deal
  async function handleCreateDeal() {
    if (!dealName || !orgId) return

    const { data, error } = await supabase
      .from('deals')
      .insert({
        name: dealName,
        description: dealDescription,
        org_id: orgId,
        created_by: session.user.id,
        status: 'active'
      })
      .select()
      .single()

    if (error) {
      alert('Failed to create deal: ' + error.message)
    } else {
      setDealName('')
      setDealDescription('')
      setShowModal(false)
      router.push(`/deals/${data.id}`)
    }
  }

  if (!session) return <p className="p-4">Loading session...</p>
  if (loading) return <p className="p-4">Loading deals...</p>

  return (
    <AuthGuard>
      <div className="max-w-4xl mx-auto py-10 px-4">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Deals</h1>
          <button
            className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
            onClick={() => setShowModal(true)}
          >
            <Plus className="inline-block mr-1 w-4 h-4" />
            New Deal
          </button>
        </div>

        <table className="w-full border rounded shadow-sm text-sm">
          <thead className="bg-gray-100 text-gray-700">
            <tr>
              <th className="text-left p-3">Deal Name</th>
              <th className="text-left p-3">Status</th>
              <th className="text-left p-3">Created</th>
            </tr>
          </thead>
          <tbody>
            {deals.map((deal) => (
              <tr
                key={deal.id}
                className="border-t hover:bg-gray-50 cursor-pointer"
                onClick={() => router.push(`/deals/${deal.id}`)}
              >
                <td className="p-3">{deal.name}</td>
                <td className="p-3 capitalize">{deal.status}</td>
                <td className="p-3">{new Date(deal.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
            {deals.length === 0 && (
              <tr>
                <td colSpan="3" className="p-3 text-center text-gray-500">
                  No deals found
                </td>
              </tr>
            )}
          </tbody>
        </table>

        {showModal && (
          <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50">
            <div className="bg-white p-6 rounded shadow w-full max-w-md">
              <h2 className="text-lg font-bold mb-4">New Deal</h2>
              <input
                type="text"
                className="w-full border rounded p-2 mb-3"
                placeholder="Deal name"
                value={dealName}
                onChange={(e) => setDealName(e.target.value)}
              />
              <textarea
                className="w-full border rounded p-2 mb-4"
                placeholder="Description (optional)"
                value={dealDescription}
                onChange={(e) => setDealDescription(e.target.value)}
              />
              <div className="flex justify-end gap-2">
                <button
                  onClick={() => setShowModal(false)}
                  className="px-3 py-2 text-sm bg-gray-200 rounded"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCreateDeal}
                  className="px-3 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Create
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AuthGuard>
  )
}
