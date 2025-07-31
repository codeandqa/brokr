// pages/signup.js
import { useState } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '../lib/supabaseClient'

export default function Signup() {
  const [orgName, setOrgName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()

  const handleSignup = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      // 1. Sign up the user via Supabase Auth
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email,
        password
      })

      if (signUpError || !authData?.user) {
        setError(signUpError?.message || 'Failed to create user')
        setLoading(false)
        return
      }

      const userId = authData.user.id

      // 2. Call Edge Function to create org + link user + trial subscription
      const fnRes = await fetch('/functions/v1/create-trial-org', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          org_name: orgName,
          user_id: userId,
          user_email: 'shahi.aditya@gmail.com'
        })
      })

      const fnResult = await fnRes.json()
      if (!fnRes.ok) {
        throw new Error(fnResult.error || 'Failed to create trial organization')
      }

      // 3. Redirect to dashboard
      router.push('/dashboard')
    } catch (err) {
      setError(err.message || 'Signup failed')
    }

    setLoading(false)
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 px-4">
      <form onSubmit={handleSignup} className="bg-white p-8 rounded shadow max-w-md w-full space-y-4">
        <h1 className="text-2xl font-bold text-gray-800">Start Your Free Trial</h1>

        {error && <p className="text-red-600 text-sm">{error}</p>}

        <div>
          <label className="block text-sm text-gray-600 mb-1">Organization Name</label>
          <input
            type="text"
            value={orgName}
            onChange={(e) => setOrgName(e.target.value)}
            required
            className="w-full px-3 py-2 border rounded"
          />
        </div>

        <div>
          <label className="block text-sm text-gray-600 mb-1">Email</label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            className="w-full px-3 py-2 border rounded"
          />
        </div>

        <div>
          <label className="block text-sm text-gray-600 mb-1">Password</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            className="w-full px-3 py-2 border rounded"
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-indigo-600 text-white py-2 rounded hover:bg-indigo-700"
        >
          {loading ? 'Creating Account...' : 'Start Free Trial'}
        </button>
      </form>
    </div>
  )
}