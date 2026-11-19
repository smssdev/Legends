// كل درجة من 1 (ضعيف) إلى 5 (ممتاز)، والأوزان تقول ما يهم هذا الفريق
const criteria = { fit: 5, learn: 3, speed: 3, community: 2, cost: 2 } as const;
type Criterion = keyof typeof criteria;

const names: Record<Criterion, string> = {
  fit: "يناسب أدواتنا", learn: "سهل التعلم", speed: "سرعة الاختبارات", community: "المجتمع والتوثيق", cost: "الكلفة",
};

const options: Record<string, Record<Criterion, number>> = {
  Playwright: { fit: 5, learn: 3, speed: 4, community: 4, cost: 5 },
  Cypress: { fit: 4, learn: 5, speed: 3, community: 5, cost: 4 },
  "الاختبار اليدوي وحده": { fit: 2, learn: 5, speed: 1, community: 3, cost: 2 },
};

function total(scores: Record<Criterion, number>, weights: Record<Criterion, number>): number {
  return (Object.keys(weights) as Criterion[]).reduce((sum, c) => sum + scores[c] * weights[c], 0);
}

function winner(weights: Record<Criterion, number>): string {
  return Object.entries(options).sort(([, a], [, b]) => total(b, weights) - total(a, weights))[0]![0];
}

console.log("الخيار".padEnd(22) + "النتيجة");
for (const [name, scores] of Object.entries(options)) console.log(name.padEnd(22) + total(scores, criteria));
console.log(`الفائز: ${winner(criteria)}`);

// أي خيار يفوز لو كان معيار واحد أهم بمرتين؟
for (const c of Object.keys(criteria) as Criterion[]) {
  console.log(`  إذا "${names[c]}" حُسب مرتين → ${winner({ ...criteria, [c]: criteria[c] * 2 })}`);
}
