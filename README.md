# 🏢 Brokr – Commercial Real Estate Deal Tracker (Multi-Tenant SaaS)

Brokr is a full-featured multi-tenant SaaS application built for managing the lifecycle of Commercial Real Estate (CRE) deals. It includes secure user onboarding, role-based access control, deal tracking with custom stages, Stripe billing (trial-ready), audit logs, and regional analytics.

---

## 🚀 Tech Stack

- **Next.js 14+** (App Router-ready)
- **Supabase** (Postgres + Auth + Storage + RLS)
- **Tailwind CSS** (responsive styling)
- **Stripe** (subscriptions & metered billing)
- **SendGrid / MailerSend** (email)
- **Edge Functions** (user/org onboarding, cleanup, signature sync)

---

## ⚙️ Features

- 🔐 Supabase Auth with RLS and role management
- 🏢 Multi-tenant orgs with isolated data
- 🎯 Kanban-style deal stage tracking
- ✍️ Signature block + OpenSign integration
- 📊 Regional analytics dashboard
- 📝 Audit logs with triggers
- 💰 Trial & paid subscription billing (Stripe)
- 📤 Email triggers (onboarding, role updates, signatures)
- 📦 GitHub Actions CI/CD support

---

## 🛠 Local Development Setup

### 1. Clone the Repo

```bash
git clone https://github.com/codeandqa/brokr.git
cd brokr
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Set Up Supabase

Install the Supabase CLI if not already:

```bash
npm install -g supabase
```

Start Supabase locally:

```bash
supabase start
```

Reset the local database:

```bash
supabase db reset
```

This will apply the schema from the latest SQL migration (e.g. `cleaned_brokr_schema.sql`).

---

### 4. Configure Environment Variables

Create `.env.local` using the provided `.env.sample`:

```bash
cp .env.sample .env.local
```

Update the following in `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_JWT_SECRET=your-jwt-secret
```

You can get these from your Supabase project's dashboard or from the CLI output after `supabase start`.

---

### 5. Run the App

```bash
npm run dev
```

Visit: [http://localhost:3000](http://localhost:3000)

---

## 🔁 Edge Functions

Brokr uses Supabase Edge Functions for key server-side logic.

### Create & Deploy Edge Functions

```bash
supabase functions deploy create-trial-org
supabase functions serve create-trial-org
```

Repeat for other functions like:

- `trial-cleanup`
- `role-summary`
- `opensign-poll`

All functions live in: `supabase/functions/`

---

## 🔐 Auth Roles

| Role         | Description                 |
|--------------|-----------------------------|
| `super_admin`| Global access & analytics   |
| `admin`      | Full org access, invites    |
| `broker`     | Works deals, limited access |
| `viewer`     | Read-only access            |

---

## 🧪 Testing

- Unit tests (coming soon) go in `/__tests__/`
- Trigger audit logs via inserts/updates to `deals`
- Use `/admin/logs.js` to view RLS-protected change history

---

## 🧹 Trial Expiration Cleanup

Auto-delete or flag expired trials:

```bash
supabase functions deploy trial-cleanup
```

You can also schedule it via GitHub Actions in `.github/workflows/cleanup.yml`

---

## 🧾 Billing Plans (Stripe)

| Plan        | Price           | Limits                            |
|-------------|------------------|------------------------------------|
| `trial`     | Free (30 days)   | 1 admin, 2 brokers, no file upload |
| `pro`       | $15/user/month   | Full access                        |
| `enterprise`| $35/user/month   | SLA + advanced controls            |

---

## 📁 Project Structure

```
brokr/
│
├── pages/               # Routes (login, signup, dashboard, etc.)
├── components/          # Reusable UI
├── lib/                 # Supabase client, helpers
├── supabase/
│   ├── functions/       # Edge Functions (TS)
│   └── migrations/      # SQL schema
├── public/              # Static assets
├── styles/              # Tailwind config
├── .env.sample
├── README.md
```

---

## 📦 Deployment (Vercel)

1. Push to GitHub
2. Connect to Vercel
3. Set the `.env` values in Vercel dashboard
4. Trigger production build

---

## 📚 License

MIT © [Aditya Kumar](https://github.com/codeandqa)
