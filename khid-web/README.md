# Khidmeti Web

Marketing site (public) **+** admin dashboard for the Khidmeti platform.
React 18 · Vite · TypeScript · Tailwind · TanStack Query · Firebase Auth · i18n (ar/fr/en, RTL).

Shares the **Midnight Indigo** theme and the same Firebase project + NestJS API as
the mobile app (`khid-app`) and backend (`khid-back`).

## Structure
```
src/
  i18n/          trilingual strings (ar/fr/en) + RTL switching
  lib/           api client, firebase, auth, theme, types
  components/    ui primitives + layout (nav, footer, logo, controls)
  features/
    marketing/   public landing (Hero, Services, HowItWorks, ForWorkers, Features, Faq, Download)
    admin/       login, RequireAdmin guard, AdminLayout, pages/*
```

## Setup
```bash
cp .env.example .env      # fill Firebase web config + API URL
npm install
npm run dev               # http://localhost:5173  (proxies /api → localhost:3000)
```

## Environment (`.env`)
| var | purpose |
|-----|---------|
| `VITE_API_BASE_URL` | API origin. `/api` in dev (proxied), full URL in prod. |
| `VITE_DEV_API_TARGET` | where the dev `/api` proxy forwards (default `http://localhost:3000`). |
| `VITE_FIREBASE_*` | Firebase web app config — **same project** as the mobile app. |
| `VITE_APP_ANDROID_URL` / `VITE_APP_IOS_URL` | store links for the download CTA. |

## Admin access
Admin auth reuses Firebase (email/password). The backend `AdminGuard` requires the
user's Mongo `role` to be `admin`. Create the first admin from the backend:

```bash
# in khid-back — the account must be able to sign into Firebase first
make scripts-promote-admin ARGS="--email you@example.com"
# or create a fresh profile directly:
make scripts-promote-admin ARGS="--uid <firebase-uid> --name 'Admin' --email you@example.com"
```

Then sign in at `/admin/login`.

## Build
```bash
npm run build     # tsc + vite build + prerender → dist/
npm run preview
```

### Prerendering (SEO)
`npm run build` also prerenders the public routes (`/`, `/legal/privacy`,
`/legal/terms`) to static HTML via `src/entry-server.tsx` +
`scripts/prerender.mjs`, so crawlers and social scrapers see real content
(with per-route `<title>`/canonical) instead of an empty SPA shell. The
client bundle re-renders over the static markup on load. `/admin` is not
prerendered (auth-gated; disallowed in `robots.txt`).

Deployment note: serve `dist/` with a static host that falls back to
`/index.html` for unknown paths (SPA fallback) — the prerendered
`legal/*/index.html` files are picked up automatically by any static server.

> Add the web origin (e.g. `http://localhost:5173`) to `CORS_ORIGINS` in `khid-back/.env`.

## Note: running from an SD-card / FUSE path
`/storage/emulated/0` (Android shared storage) does **not** support symlinks, so a
plain `npm install` fails when creating `node_modules/.bin` links. Two options:

1. **Recommended** — copy/clone this folder to a normal filesystem (e.g. `~/khid-web`)
   and run `npm install` / `npm run dev` there.
2. **In place** — install without bin links and invoke tools via `node`:
   ```bash
   npm install --no-bin-links
   node node_modules/vite/bin/vite.js dev      # or: ... vite.js build
   node node_modules/typescript/bin/tsc --noEmit
   ```

> Verified: `tsc --noEmit` passes with 0 errors and `vite build` succeeds
> (route-based code-splitting keeps the public site light; charts load only in
> the dashboard, and Firebase is dynamically imported so the marketing site
> ships zero Firebase bytes).
