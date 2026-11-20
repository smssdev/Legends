import pg from "pg";

pg.types.setTypeParser(pg.types.builtins.INT8, (value) => Number(value));

// two pools: writes always go to the primary, reads usually to the replica
export const primary = new pg.Pool({ connectionString: process.env.PRIMARY_URL });
export const replica = new pg.Pool({ connectionString: process.env.REPLICA_URL });

const lastWrite = new Map<string, number>();

export async function write(user: string, sql: string, params: unknown[]) {
  const result = await primary.query(sql, params);
  lastWrite.set(user, Date.now());
  return result;
}

// read your own writes: for 5 seconds after a user writes, their reads go to the primary
export function readerFor(user: string) {
  const at = lastWrite.get(user);
  return at !== undefined && Date.now() - at < 5000 ? primary : replica;
}
