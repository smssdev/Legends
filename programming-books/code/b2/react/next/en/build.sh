# Create the project
$ npx create-next-app@latest bit-shop --ts --app --eslint --no-tailwind --no-src-dir --use-npm
Success! Created bit-shop at ~/code/bit-shop
# Build for production
$ npm run build
Route (app)           Revalidate  Expire
┌ ○ /
├ ○ /_not-found
├ ƒ /api/products
├ ○ /contact
├ ○ /products                 1m      1h
└   /products/[id]
  ├ ◐ /products/[id]
  ├ ◐ /products/1
  ├ ◐ /products/2
  └ ◐ /products/3
○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
ƒ  (Dynamic)            server-rendered on demand
