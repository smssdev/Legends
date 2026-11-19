// Newest first, like "new arrivals". Page 1 is read, then a product is added.
type Row = { id: number };
// 6, 5, 4, 3, 2, 1
let rows: Row[] = Array.from({ length: 6 }, (_, i) => ({ id: 6 - i }));
const ids = (page: Row[]) => page.map((r) => r.id).join(", ");

const byOffset = (offset: number) => rows.slice(offset, offset + 3);
const byCursor = (after = Infinity) => rows.filter((r) => r.id < after).slice(0, 3);

const offsetPage1 = byOffset(0);
const cursorPage1 = byCursor();
rows = [{ id: 7 }, ...rows];
const cursorPage2 = byCursor(cursorPage1.at(-1)?.id);
console.log("a new product arrives: id 7");
console.log(`offset: page 1 = ${ids(offsetPage1)} | page 2 = ${ids(byOffset(3))}`);
console.log(`cursor: page 1 = ${ids(cursorPage1)} | page 2 = ${ids(cursorPage2)}`);
