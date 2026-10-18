# Legends web

Vue 3 + Vite + Pinia + Tailwind 4, Arabic RTL. Colors, fonts and sizes come from
`docs/design/tokens.json` (generated into `src/styles/tokens.css` before dev and build).

```bash
npm install
npm run dev     # http://localhost:5173, /api proxied to the Laravel API on :8000
npm run build
```

Run everything (API, queue, scheduler, web) from `backend/` with `composer dev`.
