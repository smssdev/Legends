// مستنتجة: تعرف TypeScript هذه الأنواع دون أن تُخبَر
let city = "القاهرة";
const year = 2026;
const scores = [72, 95, 88];

// اكتب أنواع معاملات الدالة ونوع ما تُرجعه
function average(values: number[]): number {
  return values.reduce((sum, v) => sum + v, 0) / values.length;
}

function greet(name: string, title?: string): string {
  return title ? `${title} ${name}` : name;
}

console.log(city, year, average(scores));
console.log(greet("سارة"), "|", greet("سارة", "د."));
