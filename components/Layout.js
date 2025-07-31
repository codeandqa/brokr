// components/Layout.js
import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '../lib/supabaseClient'

export default function Layout({ children }) {
  const router = useRouter()
  const [email, setEmail] = useState('')

  useEffect(() => {
    const fetchUser = async () => {
      const { data } = await supabase.auth.getUser()
      if (data?.user) {
        setEmail(data.user.email)
      } else {
        router.push('/login')
      }
    }

    fetchUser()
  }, [router])

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="w-full bg-white border-b px-6 py-4 flex justify-between items-center shadow-sm">
        <div className="text-sm text-gray-700">
          {email ? `Signed in as ${email}` : 'Loading...'}
        </div>
        <button
          onClick={handleLogout}
          className="bg-red-500 text-white text-sm px-4 py-2 rounded hover:bg-red-600 transition"
        >
          Logout
        </button>
      </header>

      <main className="p-6 max-w-6xl mx-auto">{children}</main>
    </div>
  )
}
