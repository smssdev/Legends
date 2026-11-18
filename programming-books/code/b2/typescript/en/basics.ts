// Inferred: TypeScript knows these types without being told
let city = "Cairo";
const year = 2026;
const scores = [72, 95, 88];

// Annotate function parameters and the return type
function average(values: number[]): number {
  return values.reduce((sum, v) => sum + v, 0) / values.length;
}

function greet(name: string, title?: string): string {
  return title ? `${title} ${name}` : name;
}

console.log(city, year, average(scores));
console.log(greet("Sara"), "|", greet("Sara", "Dr."));
