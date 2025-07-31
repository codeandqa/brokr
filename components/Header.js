// components/Header.js
import Link from 'next/link'
import { useRouter } from 'next/router'
import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabaseClient'

export default function Header() {
  const router = useRouter()
  const [user, setUser] = useState(null)

  useEffect(() => {
    const getUser = async () => {
      const { data } = await supabase.auth.getUser()
      if (data?.user) setUser(data.user)
    }
    getUser()
  }, [])

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <header className="bg-white shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16 items-center">
          <div className="flex items-center">
            <Link href="/" className="text-xl font-semibold text-indigo-600">
              Brokr
            </Link>
            <nav className="ml-10 space-x-4 hidden md:flex">
              <Link href="/dashboard" className="text-gray-600 hover:text-indigo-600">Dashboard</Link>
              <Link href="/deals" className="text-gray-600 hover:text-indigo-600">Deals</Link>
              <Link href="/admin/billing" className="text-gray-600 hover:text-indigo-600">Billing</Link>
              <Link href="/admin/logs" className="text-gray-600 hover:text-indigo-600">Logs</Link>
            </nav>
          </div>
          <div className="flex items-center gap-4">
            {user ? (
              <>
                <span className="text-sm text-gray-600 hidden sm:inline">{user.email}</span>
                <button
                  onClick={handleLogout}
                  className="bg-indigo-600 hover:bg-indigo-700 text-white text-sm px-4 py-2 rounded-md"
                >
                  Logout
                </button>
              </>
            ) : (
              <Link href="/login" className="text-sm text-indigo-600 hover:underline">Login</Link>
            )}
          </div>
        </div>
      </div>
    </header>
  )
}
