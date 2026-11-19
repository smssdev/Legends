# Started without its settings: it refuses to start, and says why
$ PORT=abc ALLOWED_ORIGINS=localhost node src/server.ts
Invalid configuration:
✖ Invalid input: expected number, received NaN
  → at PORT
✖ Invalid URL
  → at ALLOWED_ORIGINS[0]
