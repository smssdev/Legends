import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// مجمعان: الكتابة دائماً إلى الرئيسية، والقراءة غالباً من النسخة
export const primary = new pg.Pool({ connectionString: process.env.PRIMARY_URL });
export const replica = new pg.Pool({ connectionString: process.env.REPLICA_URL });

const lastWrite = new Map<string, number>();

export async function write(user: string, sql: string, params: unknown[]) {
  const result = await primary.query(sql, params);
  lastWrite.set(user, Date.now());
  return result;
}

// اقرأ ما كتبته: خمس ثوانٍ بعد كتابة المستخدم، تذهب قراءاته إلى الرئيسية
export function readerFor(user: string) {
  const at = lastWrite.get(user);
  return at !== undefined && Date.now() - at < 5000 ? primary : replica;
}
