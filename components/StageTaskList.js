// components/StageTaskList.js
import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabaseClient'

export default function StageTaskList({ dealId, stage }) {
  const [tasks, setTasks] = useState([])
  const [loading, setLoading] = useState(true)
  const [newTask, setNewTask] = useState('')
  const [newAssignee, setNewAssignee] = useState('')
  const [newDueDate, setNewDueDate] = useState('')
  const [users, setUsers] = useState([])
  const [adding, setAdding] = useState(false)

  useEffect(() => {
    if (!dealId || !stage) return
    fetchTasks()
    fetchUsers()
  }, [dealId, stage])

  const fetchTasks = async () => {
    setLoading(true)
    const { data, error } = await supabase
      .from('stage_tasks_with_user')
      .select('*')
      .eq('deal_id', dealId)
      .eq('stage', stage)
      .order('sort_order')

    if (!error) setTasks(data || [])
    setLoading(false)
  }

  const fetchUsers = async () => {
    const { data, error } = await supabase
      .from('users')
      .select('id, email')
      .order('email')

    if (!error) setUsers(data || [])
  }

  const toggleComplete = async (taskId, currentStatus, taskLabel) => {
    const { error } = await supabase
      .from('stage_tasks')
      .update({ is_completed: !currentStatus })
      .eq('id', taskId)

    if (!error) {
      setTasks((prev) =>
        prev.map((t) =>
          t.id === taskId ? { ...t, is_completed: !currentStatus } : t
        )
      )

      await supabase.from('audit_log').insert({
        deal_id: dealId,
        action: 'task_toggled',
        description: `${taskLabel} marked as ${!currentStatus ? 'completed' : 'incomplete'}`,
      })
    }
  }

  const handleAddTask = async (e) => {
    e.preventDefault()
    if (!newTask.trim()) return

    setAdding(true)

    const { data, error } = await supabase
      .from('stage_tasks')
      .insert({
        deal_id: dealId,
        stage,
        task_label: newTask,
        is_completed: false,
        sort_order: tasks.length,
        assigned_to: newAssignee || null,
        due_date: newDueDate || null,
      })
      .select('*, assigned_user:users(email)')
      .single()

    if (!error && data) {
      setTasks([...tasks, data])
      setNewTask('')
      setNewAssignee('')
      setNewDueDate('')

      await supabase.from('audit_log').insert({
        deal_id: dealId,
        action: 'task_added',
        description: `New task added: ${newTask}`,
      })
    }

    setAdding(false)
  }

  const percentComplete =
    tasks.length > 0
      ? Math.round((tasks.filter((t) => t.is_completed).length / tasks.length) * 100)
      : 0

  return (
    <div className="space-y-4">
      {/* Progress bar */}
      <div className="w-full bg-gray-200 rounded-full h-2">
        <div
          className="bg-indigo-600 h-2 rounded-full transition-all duration-300"
          style={{ width: percentComplete + '%' }}
        ></div>
      </div>
      <p className="text-sm text-gray-500">
        {percentComplete}% complete ({tasks.filter(t => t.is_completed).length} of {tasks.length})
      </p>

      {/* Task List */}
      <ul className="space-y-3">
        {tasks.map((task) => (
          <li key={task.id} className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 border-b pb-2">
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                checked={task.is_completed}
                onChange={() => toggleComplete(task.id, task.is_completed, task.task_label)}
                className="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
              />
              <span className={task.is_completed ? 'line-through text-gray-400' : ''}>
                {task.task_label}
              </span>
            </div>
            <div className="text-sm text-gray-500 flex gap-4">
              {task.due_date && <span>📅 {task.due_date}</span>}
              {task.assigned_user?.email && <span>👤 {task.assigned_user.email}</span>}
            </div>
          </li>
        ))}
      </ul>

      {/* Add New Task */}
      <form onSubmit={handleAddTask} className="mt-4 space-y-2 sm:space-y-0 sm:flex sm:items-center sm:gap-2">
        <input
          type="text"
          placeholder="Task label..."
          value={newTask}
          onChange={(e) => setNewTask(e.target.value)}
          className="flex-1 border px-3 py-2 rounded text-sm"
        />
        <input
          type="date"
          value={newDueDate}
          onChange={(e) => setNewDueDate(e.target.value)}
          className="border px-2 py-2 rounded text-sm"
        />
        <select
          value={newAssignee}
          onChange={(e) => setNewAssignee(e.target.value)}
          className="border px-2 py-2 rounded text-sm"
        >
          <option value="">Assign</option>
          {users.map((user) => (
            <option key={user.id} value={user.id}>{user.email}</option>
          ))}
        </select>
        <button
          type="submit"
          disabled={adding}
          className="px-4 py-2 bg-indigo-600 text-white rounded text-sm hover:bg-indigo-700"
        >
          {adding ? 'Adding...' : 'Add'}
        </button>
      </form>
    </div>
  )
}