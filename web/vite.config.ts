import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  server: {
    port: 5173,
    // The Laravel API from `php artisan serve` (see backend composer dev).
    proxy: { '/api': 'http://127.0.0.1:8000' },
  },
})
