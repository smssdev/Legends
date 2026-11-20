import pg from "pg";

const pool = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });

// ما قد يرسله نموذج على أنه بريد: يغلق علامة التنصيص ويضيف شرطاً.
const input = "x' OR '1'='1";

// خطأ: المدخل يصير جزءاً من SQL
const unsafe = await pool.query(`SELECT id, email FROM customers WHERE email = '${input}'`);
console.log("وصل النصوص:", unsafe.rowCount, "صفوف");

// صحيح: SQL والقيمة يسافران منفصلين، و$1 قيمة دائماً لا غير
const safe = await pool.query("SELECT id, email FROM customers WHERE email = $1", [input]);
console.log("معامل:", safe.rowCount, "صفوف");

const sara = await pool.query(
  "SELECT c.name, count(o.id) AS orders FROM customers c " +
    "LEFT JOIN orders o ON o.customer_id = c.id WHERE c.email = $1 GROUP BY c.name",
  ["sara@example.com"],
);
// count(*) من النوع bigint، ويُرجعه pg نصاً لأن أعداد JavaScript لا تتسع لكل bigint
console.log(sara.rows[0], typeof sara.rows[0].orders);

await pool.end();
