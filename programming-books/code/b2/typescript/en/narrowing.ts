function formatPrice(value: number | string | null): string {
  if (value === null) return "Free";
  if (typeof value === "string") return value; // here value is a string
  return `${value.toFixed(2)} EGP`; // here it can only be a number
}

type Cat = { kind: "cat"; meows: boolean };
type Dog = { kind: "dog"; barks: boolean };

function describe(pet: Cat | Dog): string {
  if ("meows" in pet) return pet.meows ? "A talkative cat" : "A quiet cat";
  return pet.barks ? "A loud dog" : "A calm dog";
}

console.log(formatPrice(19.5), "|", formatPrice("Ask us"), "|", formatPrice(null));
console.log(describe({ kind: "cat", meows: true }), "|", describe({ kind: "dog", barks: false }));
