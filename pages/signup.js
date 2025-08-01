// pages/signup.js
import { useState } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '../lib/supabaseClient'

export default function SignupPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [orgName, setOrgName] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleSignup = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      // Step 1: Sign up user
      const { data: signupData, error: signupError } = await supabase.auth.signUp({
        email,
        password
      })

      if (signupError) {
        setError(`Signup error: ${signupError.message}`)
        setLoading(false)
        return
      }

      const user = signupData?.user
      if (!user) {
        setError('Signup succeeded but no user returned.')
        setLoading(false)
        return
      }

      // Step 2: Call Edge Function to create trial org
      const { data, error: fnError } = await supabase.functions.invoke('create-trial-org', {
        body: {
          orgName,
          email,
          user_id: user.id
        }
      })

      if (fnError) {
        setError(`Failed to set up trial org: ${fnError.message}`)
        setLoading(false)
        return
      }

      alert('Account created! Please check your email to verify and then log in.')
      router.push('/login')
    } catch (err) {
      console.error('Unexpected error:', err)
      setError('Unexpected error occurred. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full bg-white p-6 rounded-lg shadow-md border">
        <h2 className="text-2xl font-bold text-gray-800 mb-4">Sign Up for a Free Trial</h2>

        <form onSubmit={handleSignup} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Organization Name</label>
            <input
              type="text"
              value={orgName}
              onChange={(e) => setOrgName(e.target.value)}
              className="mt-1 block w-full border border-gray-300 rounded-md p-2"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Email Address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 block w-full border border-gray-300 rounded-md p-2"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 block w-full border border-gray-300 rounded-md p-2"
              required
            />
          </div>

          {error && <p className="text-red-600 text-sm">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 text-white font-semibold py-2 px-4 rounded hover:bg-blue-700"
          >
            {loading ? 'Signing up...' : 'Create Free Trial'}
          </button>
        </form>
      </div>
    </div>
  )
}
