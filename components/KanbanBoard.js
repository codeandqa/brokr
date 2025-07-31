// components/KanbanBoard.js
import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabaseClient'

export default function KanbanBoard({ dealId }) {
  const [stages, setStages] = useState([])
  const [dragging, setDragging] = useState(null)

  useEffect(() => {
    fetchStages()
  }, [dealId])

  const fetchStages = async () => {
    const { data, error } = await supabase
      .from('deal_stages')
      .select('*')
      .eq('deal_id', dealId)
      .order('sort_order')

    if (!error) setStages(data)
  }

  const onDragStart = (e, index) => {
    setDragging(index)
  }

  const onDragOver = (e) => {
    e.preventDefault()
  }

  const onDrop = async (e, index) => {
    e.preventDefault()
    const newStages = [...stages]
    const [moved] = newStages.splice(dragging, 1)
    newStages.splice(index, 0, moved)
    setStages(newStages)
    setDragging(null)

    // Update sort_order in Supabase
    for (let i = 0; i < newStages.length; i++) {
      await supabase
        .from('deal_stages')
        .update({ sort_order: i })
        .eq('id', newStages[i].id)
    }
  }

  return (
    <div className="flex gap-4 flex-wrap">
      {stages.map((stage, index) => (
        <div
          key={stage.id}
          draggable
          onDragStart={(e) => onDragStart(e, index)}
          onDragOver={onDragOver}
          onDrop={(e) => onDrop(e, index)}
          className="bg-white p-4 w-60 rounded shadow cursor-move"
        >
          <h4 className="font-semibold">{stage.name}</h4>
        </div>
      ))}
    </div>
  )
}
