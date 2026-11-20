// كل الإعدادات تُقرأ وتُفحص في مكان واحد
const apiUrl = import.meta.env.VITE_API_URL;
if (!apiUrl) throw new Error("VITE_API_URL غير مضبوط: أضفه إلى ملف .env");

export const config = {
  apiUrl,
  isProduction: import.meta.env.PROD,
} as const;
