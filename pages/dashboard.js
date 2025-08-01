// pages/dashboard.js
import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabaseClient'
import AuthGuard from '../components/AuthGuard'

export default function DashboardPage() {
  const [orgInfo, setOrgInfo] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchOrgInfo = async () => {
      const { data, error } = await supabase
        .from('my_org_details')
        .select('*')
        .single()

      if (error) {
        console.error('Error fetching org info:', error.message)
      } else {
        setOrgInfo(data)
      }

      setLoading(false)
    }

    fetchOrgInfo()
  }, [])

  if (loading) return <div className="p-6">Loading...</div>
  if (!orgInfo) return <div className="p-6 text-red-600">No organization info found.</div>

  return (
    <AuthGuard>
      <div className="p-6 max-w-4xl mx-auto space-y-6">
        <h1 className="text-2xl font-bold text-gray-800">Your Organization</h1>
        <div className="bg-white shadow rounded p-6 border">
          <p><strong>Organization:</strong> {orgInfo.org_name}</p>
          <p><strong>Plan:</strong> {orgInfo.plan}</p>
          <p><strong>Created At:</strong> {new Date(orgInfo.created_at).toLocaleString()}</p>
        </div>
        <div className="bg-white shadow rounded p-6 border">
          <h2 className="text-lg font-semibold text-gray-800">Your Info</h2>
          <p><strong>Email:</strong> {orgInfo.email}</p>
          <p><strong>Role:</strong> {orgInfo.role}</p>
        </div>
      </div>
    </AuthGuard>
  )
}
