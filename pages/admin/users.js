// pages/admin/users.js

import { useEffect, useState } from 'react'
import { supabase } from '../../lib/supabaseClient'
import AuthGuard from '../../components/AuthGuard'
import { Plus, Trash2 } from 'lucide-react'
import { useSupabaseClient, useSession } from '@supabase/auth-helpers-react'
export default function AdminUsersPage() {
  const session = useSession()
  const supabase = useSupabaseClient()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [newEmail, setNewEmail] = useState('')
  const [newRole, setNewRole] = useState('broker')
  console.log('Session:', session)
  useEffect(() => {
    if (session) fetchUsers()
  }, [session])

  // // Prevent rendering before session is ready
  if (!session) return <p className="p-4">Loading session...</p>

  // ✅ Fetch users in the current admin's org
  async function fetchUsers() {
    setLoading(true)
    const { data: orgUser, error: profileError } = await supabase
      .from('org_members')
      .select('org_id')
      .eq('user_id', session.user.id)
      .single()

    if (profileError) {
      console.error('Org lookup failed:', profileError)
      return setLoading(false)
    }

    const { data, error } = await supabase
      .from('org_members')
      .select('id, role, user_id, users(email), created_at')
      .eq('org_id', orgUser.org_id)

    if (error) {
      console.error('Failed to fetch users:', error)
    } else {
      setUsers(data)
    }
    setLoading(false)
  }

  // ✅ Invite new user (email only) into org
  async function handleInvite() {
    if (!session || !session.user) {
      alert('You must be logged in to invite users.')
      return
    }

    setLoading(true)

    const { data: orgUser } = await supabase
      .from('org_members')
      .select('org_id')
      .eq('user_id', session.user.id)
      .single()

    const { error } = await supabase.rpc('invite_user_to_org', {
      email: newEmail,
      role: newRole,
      org_id: orgUser.org_id,
    })

    if (error) {
      alert('Invite failed: ' + error.message)
    } else {
      setShowModal(false)
      setNewEmail('')
      fetchUsers()
    }

    setLoading(false)
  }

  // ✅ Change role
  async function updateRole(memberId, newRole) {
    const { error } = await supabase
      .from('org_members')
      .update({ role: newRole })
      .eq('id', memberId)

    if (error) {
      alert('Failed to update role: ' + error.message)
    } else {
      fetchUsers()
    }
  }

  // ✅ Remove user
  async function removeUser(memberId) {
    const ok = confirm('Are you sure you want to remove this user?')
    if (!ok) return
    const { error } = await supabase.from('org_members').delete().eq('id', memberId)
    if (error) {
      alert('Error removing user: ' + error.message)
    } else {
      fetchUsers()
    }
  }

  return (
    <AuthGuard>
      <div className="max-w-4xl mx-auto py-10 px-4">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Organization Users</h1>
          <button
            className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
            onClick={() => setShowModal(true)}
          >
            <Plus className="inline-block mr-1 w-4 h-4" />
            Invite User
          </button>
        </div>

        {loading && <p>Loading users...</p>}

        <table className="min-w-full bg-white border rounded shadow text-sm">
          <thead className="bg-gray-100 text-gray-700">
            <tr>
              <th className="text-left p-3">Email</th>
              <th className="text-left p-3">Role</th>
              <th className="text-left p-3">Added</th>
              <th className="text-left p-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((member) => (
              <tr key={member.id} className="border-t">
                <td className="p-3">{member.users?.email}</td>
                <td className="p-3">
                  <select
                    className="border rounded p-1"
                    value={member.role}
                    onChange={(e) => updateRole(member.id, e.target.value)}
                  >
                    <option value="admin">Admin</option>
                    <option value="broker">Broker</option>
                    <option value="viewer">Viewer</option>
                    <option value="legal">Legal</option>
                  </select>
                </td>
                <td className="p-3">{new Date(member.created_at).toLocaleDateString()}</td>
                <td className="p-3">
                  <button
                    onClick={() => removeUser(member.id)}
                    className="text-red-600 hover:underline"
                  >
                    <Trash2 className="inline-block w-4 h-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {showModal && (
          <div className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50">
            <div className="bg-white rounded shadow p-6 w-96">
              <h2 className="text-lg font-semibold mb-4">Invite New User</h2>
              <input
                type="email"
                className="w-full border p-2 rounded mb-3"
                placeholder="Email"
                value={newEmail}
                onChange={(e) => setNewEmail(e.target.value)}
              />
              <select
                className="w-full border p-2 rounded mb-4"
                value={newRole}
                onChange={(e) => setNewRole(e.target.value)}
              >
                <option value="broker">Broker</option>
                <option value="viewer">Viewer</option>
                <option value="legal">Legal</option>
              </select>
              <div className="flex justify-end gap-2">
                <button
                  onClick={() => setShowModal(false)}
                  className="px-3 py-2 text-sm bg-gray-200 rounded"
                >
                  Cancel
                </button>
                <button
                  onClick={handleInvite}
                  className="px-3 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Send Invite
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AuthGuard>
  )
}
