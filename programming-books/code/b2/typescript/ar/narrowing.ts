function formatPrice(value: number | string | null): string {
  if (value === null) return "مجاناً";
  if (typeof value === "string") return value; // هنا value نص
  return `${value.toFixed(2)} جنيهاً`; // وهنا لا يمكن أن تكون إلا رقماً
}

type Cat = { kind: "cat"; meows: boolean };
type Dog = { kind: "dog"; barks: boolean };

function describe(pet: Cat | Dog): string {
  if ("meows" in pet) return pet.meows ? "قطة ثرثارة" : "قطة هادئة";
  return pet.barks ? "كلب صاخب" : "كلب هادئ";
}

console.log(formatPrice(19.5), "|", formatPrice("اسألنا"), "|", formatPrice(null));
console.log(describe({ kind: "cat", meows: true }), "|", describe({ kind: "dog", barks: false }));
