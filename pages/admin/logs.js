// pages/admin/logs.js
import { useEffect, useState } from 'react'
import { supabase } from '../../lib/supabaseClient'
import AuthGuard from '../../components/AuthGuard'

export default function AuditLogsPage() {
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [sortField, setSortField] = useState('created_at')
  const [sortDirection, setSortDirection] = useState('desc')
  const [actionFilter, setActionFilter] = useState('')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [groupBy, setGroupBy] = useState('none')

  const [page, setPage] = useState(1)
  const perPage = 10

  useEffect(() => {
    fetchLogs()
  }, [search, sortField, sortDirection, actionFilter, fromDate, toDate])

  const fetchLogs = async () => {
    setLoading(true)

    let query = supabase
      .from('audit_log')
      .select('id, deal_name, action, description, user_id, user_email, created_at')
      .order(sortField, { ascending: sortDirection === 'asc' })

    const filters = []

    if (search) {
      filters.push(`deal_name.ilike.%${search}%`)
      filters.push(`description.ilike.%${search}%`)
      filters.push(`action.ilike.%${search}%`)
      filters.push(`user_email.ilike.%${search}%`)
    }

    if (filters.length) {
      query = query.or(filters.join(','))
    }

    if (actionFilter) query = query.eq('action', actionFilter)
    if (fromDate) query = query.gte('created_at', fromDate + 'T00:00:00')
    if (toDate) query = query.lte('created_at', toDate + 'T23:59:59')

    const { data, error } = await query

    if (!error && data) {
      setLogs(data)
      setPage(1)
    }

    setLoading(false)
  }

  const handleSort = (field) => {
    if (field === sortField) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDirection('asc')
    }
  }

  const exportCSV = () => {
    const csvContent = [
      ['Timestamp', 'Deal', 'User Email', 'Action', 'Description'],
      ...logs.map((log) => [
        new Date(log.created_at).toLocaleString(),
        log.deal_name || '',
        log.user_email || log.user_id?.slice(0, 8),
        log.action,
        log.description
      ])
    ]
      .map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      .join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'audit_logs.csv'
    a.click()
    window.URL.revokeObjectURL(url)
  }

  const groupLogs = () => {
    if (groupBy === 'none') return [{ title: null, entries: logs }]
    const key = groupBy === 'deal' ? 'deal_name' : 'user_email'
    const grouped = {}
    for (const log of logs) {
      const k = log[key] || '(Unknown)'
      if (!grouped[k]) grouped[k] = []
      grouped[k].push(log)
    }
    return Object.entries(grouped).map(([title, entries]) => ({ title, entries }))
  }

  const paginatedGroups = groupLogs().map(({ title, entries }) => {
    const start = (page - 1) * perPage
    const end = start + perPage
    return { title, entries: entries.slice(start, end), total: entries.length }
  })

  return (
    <AuthGuard role="super_admin">
      <div className="p-6 max-w-7xl mx-auto">
        <h1 className="text-2xl font-bold text-gray-800 mb-4">Audit Logs</h1>

        <div className="mb-4 flex flex-wrap gap-4 items-end">
          <input
            type="text"
            placeholder="Search logs..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="border px-3 py-2 rounded w-64 text-sm"
          />

          <select
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
            className="border px-3 py-2 rounded text-sm"
          >
            <option value="">All Actions</option>
            <option value="stage_changed">Stage Changed</option>
            <option value="status_updated">Status Updated</option>
            <option value="task_added">Task Added</option>
            <option value="task_toggled">Task Toggled</option>
          </select>

          <input type="date" value={fromDate} onChange={(e) => setFromDate(e.target.value)} className="border px-3 py-2 rounded text-sm" />
          <input type="date" value={toDate} onChange={(e) => setToDate(e.target.value)} className="border px-3 py-2 rounded text-sm" />

          <select
            value={groupBy}
            onChange={(e) => setGroupBy(e.target.value)}
            className="border px-3 py-2 rounded text-sm"
          >
            <option value="none">No Grouping</option>
            <option value="deal">Group by Deal</option>
            <option value="user">Group by User</option>
          </select>

          <button
            onClick={exportCSV}
            className="px-4 py-2 bg-indigo-600 text-white rounded text-sm hover:bg-indigo-700"
          >
            Export CSV
          </button>
        </div>

        {loading ? (
          <p className="text-gray-500">Loading logs...</p>
        ) : logs.length === 0 ? (
          <p className="text-gray-500">No logs found.</p>
        ) : (
          paginatedGroups.map(({ title, entries, total }) => (
            <div key={title || 'all'} className="mb-8">
              {title && <h2 className="text-lg font-semibold mb-2">{groupBy === 'deal' ? 'Deal:' : 'User:'} {title}</h2>}
              <div className="overflow-x-auto border rounded">
                <table className="min-w-full table-auto text-sm text-left">
                  <thead>
                    <tr className="bg-gray-100 border-b">
                      <th onClick={() => handleSort('created_at')} className="px-4 py-2 cursor-pointer">Timestamp</th>
                      <th className="px-4 py-2">Deal</th>
                      <th className="px-4 py-2">User Email</th>
                      <th onClick={() => handleSort('action')} className="px-4 py-2 cursor-pointer">Action</th>
                      <th className="px-4 py-2">Description</th>
                    </tr>
                  </thead>
                  <tbody>
                    {entries.map((log) => (
                      <tr key={log.id} className="border-t hover:bg-gray-50">
                        <td className="px-4 py-2 text-gray-600">{new Date(log.created_at).toLocaleString()}</td>
                        <td className="px-4 py-2 text-gray-800">{log.deal_name || '-'}</td>
                        <td className="px-4 py-2 text-gray-800">{log.user_email || log.user_id?.slice(0, 8)}</td>
                        <td className="px-4 py-2 text-blue-700 font-semibold">{log.action}</td>
                        <td className="px-4 py-2">{log.description}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {total > perPage && (
                <div className="flex justify-center mt-4 gap-4 text-sm">
                  <button
                    disabled={page === 1}
                    onClick={() => setPage((p) => Math.max(p - 1, 1))}
                    className="px-3 py-1 border rounded disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <span>Page {page} of {Math.ceil(total / perPage)}</span>
                  <button
                    disabled={page >= Math.ceil(total / perPage)}
                    onClick={() => setPage((p) => Math.min(p + 1, Math.ceil(total / perPage)))}
                    className="px-3 py-1 border rounded disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </AuthGuard>
  )
}