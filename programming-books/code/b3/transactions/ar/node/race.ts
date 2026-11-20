import pg from "pg";

const url = "postgres://bit:secret@localhost:5432/shop";
const mode = process.argv[2] ?? "naive";
let retries = 0;

async function buy(buyer: number) {
  const db = new pg.Client(url);
  await db.connect();
  try {
    for (;;) {
      try {
        await db.query(mode === "serializable" ? "BEGIN ISOLATION LEVEL SERIALIZABLE" : "BEGIN");
        if (mode === "atomic") {
          // جملة واحدة: تفحص قاعدة البيانات المخزون وتغيّره معاً
          const taken = await db.query(
            "UPDATE products SET stock = stock - 1 WHERE id = 1 AND stock > 0",
          );
          if (taken.rowCount === 1) {
            await db.query("INSERT INTO orders (product_id, buyer) VALUES (1, $1)", [buyer]);
          }
        } else {
          // اقرأ، وقرر في الكود، ثم اكتب: السباق الكلاسيكي
          // FOR UPDATE تقفل الصف: ينتظر المشترون الآخرون هنا حتى تنتهي هذه المعاملة
          const lock = mode === "lock" ? " FOR UPDATE" : "";
          const { rows } = await db.query(`SELECT stock FROM products WHERE id = 1${lock}`);
          // الوقت الذي يمضيه تطبيق حقيقي بين القراءة والكتابة: استدعاء خدمة دفع مثلاً
          await db.query("SELECT pg_sleep(0.1)");
          if (rows[0].stock > 0) {
            await db.query("UPDATE products SET stock = $1 WHERE id = 1", [rows[0].stock - 1]);
            await db.query("INSERT INTO orders (product_id, buyer) VALUES (1, $1)", [buyer]);
          }
        }
        await db.query("COMMIT");
        return;
      } catch (error) {
        await db.query("ROLLBACK");
        // فشل التسلسل: ابدأ المعاملة كلها من جديد
        if ((error as { code?: string }).code !== "40001") throw error;
        retries++;
      }
    }
  } finally {
    await db.end();
  }
}

const admin = new pg.Client(url);
await admin.connect();
await admin.query("TRUNCATE orders; UPDATE products SET stock = 1 WHERE id = 1");
await Promise.all(Array.from({ length: 10 }, (_, i) => buy(i + 1)));
const sold = (await admin.query("SELECT count(*)::int AS n FROM orders")).rows[0].n;
const stock = (await admin.query("SELECT stock FROM products WHERE id = 1")).rows[0].stock;
console.log(
  `${mode.padEnd(12)} 1 في المخزون, ${sold} مبيعات, المخزون الآن ${stock}` +
    (mode === "serializable" ? `, ${retries} إعادات` : ""),
);
await admin.end();
