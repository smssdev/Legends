import pg from "pg";

const pool = new pg.Pool({ connectionString: "postgres://bit:secret@localhost:5432/shop" });

// What a form might send as an email: it closes the quote and adds a condition.
const input = "x' OR '1'='1";

// WRONG: the input becomes part of the SQL
const unsafe = await pool.query(`SELECT id, email FROM customers WHERE email = '${input}'`);
console.log("string concatenation:", unsafe.rowCount, "rows");

// Right: the SQL and the value travel separately; $1 is only ever a value
const safe = await pool.query("SELECT id, email FROM customers WHERE email = $1", [input]);
console.log("parameter:", safe.rowCount, "rows");

const sara = await pool.query(
  "SELECT c.name, count(o.id) AS orders FROM customers c " +
    "LEFT JOIN orders o ON o.customer_id = c.id WHERE c.email = $1 GROUP BY c.name",
  ["sara@example.com"],
);
// count(*) is a bigint; pg returns it as a string, because JavaScript numbers cannot hold every bigint
console.log(sara.rows[0], typeof sara.rows[0].orders);

await pool.end();
