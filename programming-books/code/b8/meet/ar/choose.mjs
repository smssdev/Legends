// اختيار أول للنموذج من ثلاثة أسئلة عن المهمة.
export function chooseModel({hard, longRunning, highVolume}) {
  if (highVolume && !hard) return "claude-haiku-5-5";
  if (hard && longRunning) return "claude-fable-5-2";
  if (hard) return "claude-opus-5-5";
  return "claude-sonnet-5-5";
}

const tasks = [
  ["تصنيف تذاكر الدعم", {hard: false, longRunning: false, highVolume: true}],
  ["الرد على العملاء في محادثة", {hard: false, longRunning: false, highVolume: false}],
  ["إعادة هيكلة قاعدة كود كبيرة", {hard: true, longRunning: false, highVolume: false}],
  ["تخطيط ترحيل فيه مجاهيل كثيرة", {hard: true, longRunning: true, highVolume: false}],
];
for (const [task, answers] of tasks) {
  console.log(`${task.padEnd(38)} ${chooseModel(answers)}`);
}
