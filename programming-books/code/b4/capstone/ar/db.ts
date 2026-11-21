import pg from "pg";

export const pool = new pg.Pool({
  connectionString: "postgres://app_user:app@localhost:5432/shop",
});

// كل طلب يعمل في معاملة تضبط صالونه أولاً
export async function withSalon<T>(
  salonId: number,
  work: (db: pg.PoolClient) => Promise<T>,
): Promise<T> {
  const db = await pool.connect();
  try {
    await db.query("BEGIN");
    // SET LOCAL: لهذه المعاملة وحدها؛ لا تحتفظ بها المجموعة أبداً
    await db.query("SELECT set_config('app.salon_id', $1, true)", [
      String(salonId),
    ]);
    const result = await work(db);
    await db.query("COMMIT");
    return result;
  } catch (error) {
    await db.query("ROLLBACK");
    throw error;
  } finally {
    db.release();
  }
}
