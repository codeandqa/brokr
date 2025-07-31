// pages/admin/users.js
import { useEffect, useState } from 'react'
import { supabase } from '../../lib/supabaseClient'
import AuthGuard from '../../components/AuthGuard'

export default function AdminUsers() {
  const [orgUsers, setOrgUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [currentUserId, setCurrentUserId] = useState(null)

  useEffect(() => {
    const fetchUsers = async () => {
      setLoading(true)
      setError(null)

      const {
        data: { user }
      } = await supabase.auth.getUser()
      if (!user) return

      setCurrentUserId(user.id)

      const { data, error } = await supabase.rpc('get_org_users')
      if (error) {
        setError('Failed to load users')
        return
      }
      setOrgUsers(data)
      setLoading(false)
    }

    fetchUsers()
  }, [])

  const handleRoleChange = async (memberId, newRole) => {
    const { error } = await supabase
      .from('org_members')
      .update({ role: newRole })
      .eq('id', memberId)

    if (error) {
      alert('Failed to update role')
    } else {
      setOrgUsers((prev) =>
        prev.map((u) => (u.member_id === memberId ? { ...u, role: newRole } : u))
      )
    }
  }

  const handleDeleteUser = async (memberId) => {
    if (!confirm('Are you sure?')) return

    const { error } = await supabase.from('org_members').delete().eq('id', memberId)
    if (error) {
      alert('Failed to delete user')
    } else {
      setOrgUsers((prev) => prev.filter((u) => u.member_id !== memberId))
    }
  }

  if (loading) return <div className="p-4">Loading...</div>
  if (error) return <div className="p-4 text-red-500">{error}</div>

  return (
    <AuthGuard>
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-4">Organization Users</h1>
        <table className="w-full bg-white rounded shadow text-left">
          <thead>
            <tr className="border-b">
              <th className="p-2">Name</th>
              <th className="p-2">Email</th>
              <th className="p-2">Role</th>
              <th className="p-2">Actions</th>
            </tr>
          </thead>
          <tbody>
            {orgUsers.map((user) => (
              <tr key={user.member_id} className="border-b hover:bg-gray-50">
                <td className="p-2">{user.full_name || '—'}</td>
                <td className="p-2">{user.email}</td>
                <td className="p-2">
                  <select
                    value={user.role}
                    onChange={(e) => handleRoleChange(user.member_id, e.target.value)}
                    className="border rounded px-2 py-1"
                    disabled={user.user_id === currentUserId}
                  >
                    <option value="viewer">viewer</option>
                    <option value="broker">broker</option>
                    <option value="legal">legal</option>
                    <option value="admin">admin</option>
                    <option value="super_admin">super_admin</option>
                  </select>
                </td>
                <td className="p-2">
                  {user.user_id !== currentUserId && (
                    <button
                      onClick={() => handleDeleteUser(user.member_id)}
                      className="text-red-600 hover:underline"
                    >
                      Remove
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AuthGuard>
  )
}
