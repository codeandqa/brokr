// components/Header.js
import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '../lib/supabaseClient'

export default function Header() {
  const router = useRouter()
  const [email, setEmail] = useState('')

  useEffect(() => {
    const fetchUser = async () => {
      const { data, error } = await supabase.auth.getUser()
      if (data?.user) {
        setEmail(data.user.email)
      }
    }
    fetchUser()
  }, [])

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <header className="w-full bg-gray-100 border-b shadow-sm px-6 py-4 flex justify-between items-center">
      <div className="text-gray-800 text-sm">
        {email ? `Signed in as ${email}` : 'Loading...'}
      </div>
      <button
        onClick={handleLogout}
        className="text-sm bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 transition"
      >
        Logout
      </button>
    </header>
  )
}
