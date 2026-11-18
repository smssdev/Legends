function first<T>(list: readonly T[]): T | undefined {
  return list[0];
}

function byId<T extends { id: number }>(list: readonly T[]): Map<number, T> {
  return new Map(list.map((item) => [item.id, item]));
}

type Result<T> = { ok: true; value: T } | { ok: false; error: string };

function parseAge(text: string): Result<number> {
  const age = Number(text);
  if (!Number.isInteger(age) || age < 0) return { ok: false, error: `"${text}" ليس عمراً` };
  return { ok: true, value: age };
}

const products = [
  { id: 1, name: "كتاب", price: 25 },
  { id: 2, name: "كوب", price: 8 },
];
console.log(first(products)?.name, first<number>([]));
console.log(byId(products).get(2)?.price);
for (const text of ["34", "-2", "abc"]) {
  const result = parseAge(text);
  console.log(result.ok ? `العمر: ${result.value}` : result.error);
}
