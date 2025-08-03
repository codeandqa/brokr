import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '../lib/supabaseClient'
import AuthGuard from '../components/AuthGuard'
import { useSession } from '@supabase/auth-helpers-react'

export default function Dashboard() {
  const [user, setUser] = useState(null)
  const [org, setOrg] = useState(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const session = useSession()
  console.log('Session:', session)

  useEffect(() => {
    const fetchDashboardData = async () => {
      const { data: userResult } = await supabase.auth.getUser()
      const currentUser = userResult?.user

      if (!currentUser) {
        router.push('/login')
        return
      }

      setUser(currentUser)

      // Get user's org_id from org_members
      const { data: membership } = await supabase
        .from('org_members')
        .select('org_id, role')
        .eq('user_id', currentUser.id)
        .single()
      console.log('Membership:', membership.org_id)

      if (!membership) {
        setLoading(false)
        return
      }

      // Fetch org info
      const { data: orgInfo } = await supabase
        .from('organizations')
        .select('name, plan, status')
        .eq('id', membership.org_id)
        .single()

      console.log('Org Info:', orgInfo)
          
      setOrg({
        ...orgInfo,
        role: membership.role
      })

      setLoading(false)
    }

    fetchDashboardData()
  }, [])

  if (loading) return <div className="p-6">Loading...</div>

  return (
    <AuthGuard>
      <div className="max-w-3xl mx-auto mt-10 bg-white shadow rounded-lg p-6 border">
        <h2 className="text-2xl font-bold mb-6 text-gray-800">Dashboard</h2>

                <div>
          <div class="grid grid-cols-1 gap-4 lg:grid-cols-2 lg:gap-7 2xl:gap-x-32">
            <div>
              <p class="mb-2 text-xs leading-normal text-gray-500 dark:text-gray-400">Name</p>
              <p class="text-sm font-medium text-gray-800 dark:text-white/90">{org.name}</p>
            </div>
            <div>
              <p class="mb-2 text-xs leading-normal text-gray-500 dark:text-gray-400">Plan</p>
              <p class="text-sm font-medium text-gray-800 dark:text-white/90">{org.plan.charAt(0).toUpperCase() + org.plan.slice(1).toLowerCase()}</p>
            </div>
            <div>
              <p class="mb-2 text-xs leading-normal text-gray-500 dark:text-gray-400">status</p>
              <span className="inline-block px-3 py-1 mt-1 text-sm rounded-full bg-green-100 text-green-800 border border-green-300">
                {org.status.charAt(0).toUpperCase() + org.status.slice(1).toLowerCase()}
              </span>
            </div>
            <div>
              <p class="mb-2 text-xs leading-normal text-gray-500 dark:text-gray-400">Role</p>
              <p class="text-sm font-medium text-gray-800 dark:text-white/90">{org.role}</p>
            </div>

          </div>
        </div>
      </div>
      


      
     
    </AuthGuard>
  )
}
