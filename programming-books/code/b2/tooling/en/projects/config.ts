// All settings are read and checked in one place
const apiUrl = import.meta.env.VITE_API_URL;
if (!apiUrl) throw new Error("VITE_API_URL is not set: add it to a .env file");

export const config = {
  apiUrl,
  isProduction: import.meta.env.PROD,
} as const;
