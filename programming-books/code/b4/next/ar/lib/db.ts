// server-only: استيراد هذا الملف من مكوّن عميل يُفشل البناء
import "server-only";
import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// مجمع واحد لكل عملية، محفوظ على globalThis: Next يعيد تحميل الوحدات أثناء التطوير
const saved = globalThis as unknown as { pool?: pg.Pool };
export const pool = (saved.pool ??= new pg.Pool({
  connectionString: process.env.DATABASE_URL,
}));
