import pg from "pg";

const url = "postgres://bit:secret@localhost:5432/shop";
const level = process.argv[2] ?? "READ COMMITTED";
const a = new pg.Client(url);
const b = new pg.Client(url);
await a.connect();
await b.connect();
const price = async () => (await a.query("SELECT price FROM products WHERE id = 1")).rows[0].price;

// A reads, B changes and commits, A reads again, then A tries to change it
await a.query(`BEGIN ISOLATION LEVEL ${level}`);
console.log("A reads the price:", await price());
await b.query("UPDATE products SET price = 50000 WHERE id = 1");
console.log("B sets the price to 50000 and commits");
console.log("A reads it again:", await price());
try {
  await a.query("UPDATE products SET price = price + 1000 WHERE id = 1");
  await a.query("COMMIT");
  console.log("A adds 1000 to the price:", (await a.query("SELECT price FROM products WHERE id = 1")).rows[0].price);
} catch (error) {
  await a.query("ROLLBACK");
  console.log("A adds 1000 to the price: ERROR", (error as Error).message);
}
await b.query("UPDATE products SET price = 45000 WHERE id = 1");
await a.end();
await b.end();
