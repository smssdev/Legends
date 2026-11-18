# ملفا إعدادات
$ cat .env.development .env.production
VITE_API_URL=http://localhost:8000
VITE_API_URL=https://api.bits-shop.example
# ابنِ الموقع للإنتاج
$ npm run build
✓ built in 72ms
# أي عنوان دخل الملف المبني؟
$ grep -o 'https://[a-z.-]*example' dist/assets/index-*.js
https://api.bits-shop.example
