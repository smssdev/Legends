import pg from "pg";

export const pool = new pg.Pool({
  connectionString: "postgres://app_user:app@localhost:5432/shop",
});

// every request runs in a transaction that sets its salon first
export async function withSalon<T>(
  salonId: number,
  work: (db: pg.PoolClient) => Promise<T>,
): Promise<T> {
  const db = await pool.connect();
  try {
    await db.query("BEGIN");
    // SET LOCAL: this transaction only; the pool never keeps it
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
