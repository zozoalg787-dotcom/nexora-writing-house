# Nexora Writing House

Next.js + Supabase starter for a customer website/dashboard and secure admin foundation.

## Deploy
1. Create a Supabase project.
2. Open Supabase SQL Editor and run `supabase/schema.sql`.
3. Create a GitHub repository and upload this folder.
4. Import the repository into Vercel.
5. Add the variables from `.env.example` in Vercel Project Settings > Environment Variables.
6. Redeploy.

## Important
Never put `SUPABASE_SERVICE_ROLE_KEY` in client-side code. Keep it server-side only.

The supplied UI covers the public website, customer registration/login/dashboard, project/plan data from Supabase, and an admin authorization foundation. Payment proofs, storage uploads, chat, complaints, referrals, payouts, OTP and notifications can be added as the next modules using the same RLS/security structure.
