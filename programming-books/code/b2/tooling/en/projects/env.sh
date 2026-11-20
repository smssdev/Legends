# Two settings files
$ cat .env.development .env.production
VITE_API_URL=http://localhost:8000
VITE_API_URL=https://api.bits-shop.example
# Build the site for production
$ npm run build
✓ built in 78ms
# Which address went into the built file?
$ grep -o 'https://[a-z.-]*example' dist/assets/index-*.js
https://api.bits-shop.example
