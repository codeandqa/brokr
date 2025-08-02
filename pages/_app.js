// // pages/_app.js
// import '../styles/globals.css'
// import Header from '../components/Header'
// import { SessionContextProvider } from '@supabase/auth-helpers-react'

// export default function App({ Component, pageProps }) {
//   return (
//     <>
//       <Header />
//       <main className="pt-6">
//         <Component {...pageProps} />
//       </main>
//     </>
//   )
// }

import '../styles/globals.css'
import { useState } from 'react'
import { createPagesBrowserClient } from '@supabase/auth-helpers-nextjs'
import { SessionContextProvider } from '@supabase/auth-helpers-react'
import Header from '../components/Header'


export default function App({ Component, pageProps }) {
  const [supabaseClient] = useState(() => createPagesBrowserClient())

  return (
    
    <SessionContextProvider supabaseClient={supabaseClient} initialSession={pageProps.initialSession}>
      <Header />
      <Component {...pageProps} />
    </SessionContextProvider>
  )
}