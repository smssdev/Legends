// الأثر، وإمكان التراجع، وإمكان الفحص تقرر كم تثق بالنموذج في مهمة.
// Each factor from 1 (low) to 3 (high).
export function trustLevel({impact, irreversible, hardToCheck}) {
  const risk = impact * irreversible * hardToCheck;
  if (risk <= 4) return "استخدمه: نظرة سريعة تكفي";
  if (risk <= 12) return "استخدمه، وتحقق قبل التنفيذ";
  return "لا تعتمد عليه: يقرر إنسان";
}

const tasks = [
  ["أفكار أسماء لمشروب جديد", {impact: 1, irreversible: 1, hardToCheck: 1}],
  ["مسودة أولى لملف اختبارات", {impact: 2, irreversible: 1, hardToCheck: 1}],
  ["ملخص اجتماع للفريق", {impact: 2, irreversible: 2, hardToCheck: 2}],
  ["إعلان سعر لكل العملاء", {impact: 3, irreversible: 3, hardToCheck: 1}],
  ["قرار استرداد مبلغ لعميل", {impact: 3, irreversible: 3, hardToCheck: 2}],
];
for (const [task, factors] of tasks) {
  console.log(`${task.padEnd(38)} ${trustLevel(factors)}`);
}
