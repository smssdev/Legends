import pg from "pg";

const url = "postgres://bit:secret@localhost:5432/shop";
const level = process.argv[2] ?? "READ COMMITTED";
const a = new pg.Client(url);
const b = new pg.Client(url);
await a.connect();
await b.connect();
const price = async () => (await a.query("SELECT price FROM products WHERE id = 1")).rows[0].price;

// A تقرأ، وB تغيّر وتثبّت، وA تقرأ مرة أخرى، ثم تحاول A أن تغيّر
await a.query(`BEGIN ISOLATION LEVEL ${level}`);
console.log("A تقرأ السعر:", await price());
await b.query("UPDATE products SET price = 50000 WHERE id = 1");
console.log("B تضبط السعر على 50000 وتثبّت");
console.log("A تقرؤه مرة أخرى:", await price());
try {
  await a.query("UPDATE products SET price = price + 1000 WHERE id = 1");
  await a.query("COMMIT");
  console.log("A تضيف 1000 إلى السعر:", (await a.query("SELECT price FROM products WHERE id = 1")).rows[0].price);
} catch (error) {
  await a.query("ROLLBACK");
  console.log("A تضيف 1000 إلى السعر: ERROR", (error as Error).message);
}
await b.query("UPDATE products SET price = 45000 WHERE id = 1");
await a.end();
await b.end();
