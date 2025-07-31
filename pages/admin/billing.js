// pages/admin/billing.js
import { useEffect, useState } from 'react'
import { supabase } from '../../lib/supabaseClient'
import AuthGuard from '../../components/AuthGuard'

export default function BillingPage() {
  const [subscription, setSubscription] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetchSubscription()
  }, [])

  const fetchSubscription = async () => {
    setLoading(true)
    const { data: userData, error: userError } = await supabase.auth.getUser()
    if (userError || !userData?.user?.id) {
      setError('Not logged in')
      setLoading(false)
      return
    }

    const { data: orgMember, error: orgError } = await supabase
      .from('org_members')
      .select('org_id')
      .eq('user_id', userData.user.id)
      .single()

    if (orgError || !orgMember?.org_id) {
      setError('Could not determine your organization')
      setLoading(false)
      return
    }

    const { data, error } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('organization_id', orgMember.org_id)
      .single()

    if (error) {
      setError('Subscription not found')
    } else {
      setSubscription(data)
    }
    setLoading(false)
  }

  const formatDate = (iso) => {
    return iso ? new Date(iso).toLocaleDateString() : '—'
  }

  return (
    <AuthGuard role="admin">
      <div className="max-w-3xl mx-auto p-6 space-y-6">
        <h1 className="text-2xl font-bold text-gray-800">Billing & Plan</h1>

        {loading && <p className="text-gray-500">Loading...</p>}
        {error && <p className="text-red-600">{error}</p>}

        {!loading && !error && subscription && (
          <div className="bg-white border rounded-xl p-6 shadow space-y-4">
            <div>
              <h2 className="text-lg font-semibold text-gray-700">Current Plan:</h2>
              <span className="inline-block px-3 py-1 mt-1 text-sm rounded-full bg-blue-100 text-blue-800 border border-blue-300">
                {subscription.plan.toUpperCase()}
              </span>
            </div>

            <div>
              <h2 className="text-lg font-semibold text-gray-700">Status:</h2>
              <p className="text-gray-800 mt-1">{subscription.status}</p>
            </div>

            {subscription.trial_ends_at && (
              <div>
                <h2 className="text-lg font-semibold text-gray-700">Trial Ends:</h2>
                <p className="text-gray-800 mt-1">{formatDate(subscription.trial_ends_at)}</p>
              </div>
            )}

            <div className="pt-4">
              <button className="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 text-sm">
                Upgrade Plan
              </button>
            </div>
          </div>
        )}
      </div>
    </AuthGuard>
  )
}