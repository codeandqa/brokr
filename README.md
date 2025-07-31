# Brokr – MVP

This is a working MVP for the **Brokr** multi-tenant SaaS app to manage Commercial Real Estate (CRE) deals.

## 🚀 Getting Started

### 1. Clone the repo and install dependencies
```bash
npm install
```

### 2. Setup Supabase
- Create a project on [https://supabase.com](https://supabase.com)
- Add a `.env.local` file using `.env.sample`
- Enable email/password auth in Supabase dashboard
- Copy your Supabase URL and Anon Key

### 3. Run the app locally
```bash
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000)

### 4. Deploy to Vercel
- Push to GitHub
- Connect to Vercel
- Set up environment variables in Vercel dashboard

## 🔐 Auth
- Uses Supabase Auth
- `AuthGuard` component redirects unauthenticated users

## ✅ Pages Included
- `/login`
- `/dashboard` (protected)

## 📁 Folder Structure
- `lib/` – Supabase client
- `components/` – AuthGuard
- `pages/` – Login, Dashboard, Admin etc.

## 🛠 Tech Stack
- Next.js 14+
- Supabase
- Tailwind CSS
