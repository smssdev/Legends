// الأحدث أولاً، مثل «وصل حديثاً». تُقرأ الصفحة 1، ثم يُضاف منتج.
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
console.log("يصل منتج جديد: رقمه 7");
console.log(
  `الإزاحة: الصفحة 1 = ${ids(offsetPage1)} | الصفحة 2 = ${ids(byOffset(3))}`,
);
console.log(
  `المؤشر: الصفحة 1 = ${ids(cursorPage1)} | الصفحة 2 = ${ids(cursorPage2)}`,
);
