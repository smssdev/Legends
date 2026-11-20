import pg from "pg";
import { setTimeout as sleep } from "node:timers/promises";

const url = "postgres://bit:secret@localhost:5432/shop";
const take = (db: pg.Client, id: number) =>
  db.query("UPDATE products SET stock = stock + 1 WHERE id = $1", [id]);

// A تقفل المنتج 1 ثم 2، وB تقفل 2 ثم 1
async function run(name: string, first: number, second: number) {
  const db = new pg.Client(url);
  await db.connect();
  try {
    await db.query("BEGIN");
    await take(db, first);
    await sleep(200);
    await take(db, second);
    await db.query("COMMIT");
    console.log(`${name}: انتهت`);
  } catch (error) {
    await db.query("ROLLBACK");
    console.log(`${name}: فشلت, ${(error as { code?: string }).code}, ${(error as Error).message}`);
  } finally {
    await db.end();
  }
}

// "ordered": كلتاهما تقفل الرقم الأصغر أولاً (جواب التمرين 3)
const ordered = process.argv[2] === "ordered";
await Promise.all([run("A", 1, 2), ordered ? run("B", 1, 2) : run("B", 2, 1)]);
