// الشهر نفسه في كل مرة: بذرة ثابتة، لا Math.random()
function random(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  };
}

// ما تعطل هذا الشهر (اليوم، والساعة، والدقيقة، والمدة، ونسبة الفشل)
export const events = [
  // نشرٌ يفشل 4 دقائق ثم يُتراجع عنه
  { day: 9, at: 14 * 60 + 2, minutes: 4, rate: 0.04 },
  // تنفد اتصالات قاعدة البيانات
  { day: 17, at: 20 * 60 + 15, minutes: 35, rate: 0.25 },
  // إصدار جديد يُفشل صفحة دفع من كل 250، يومين
  { day: 24, at: 0, minutes: 2 * 1440, rate: 0.004 },
];

const eventAt = (i: number) =>
  events.find(
    (e) =>
      i >= (e.day - 1) * 1440 + e.at && i < (e.day - 1) * 1440 + e.at + e.minutes,
  );
export const during = (i: number) => eventAt(i) !== undefined;

export type Minute = {
  day: number;
  time: string;
  requests: number;
  failed: number;
};

export function month(): Minute[] {
  const next = random(2026);
  const minutes: Minute[] = [];
  for (let i = 0; i < 30 * 1440; i++) {
    const day = Math.floor(i / 1440) + 1;
    const ofDay = i % 1440;
    // هادئ في 03:00، وأزحم في 15:00: من 40 إلى 340 طلباً في الدقيقة
    const requests = Math.round(
      190 - 150 * Math.cos(((ofDay - 180) / 1440) * 2 * Math.PI),
    );
    const rate = eventAt(i)?.rate ?? 0.0002;
    let failed = 0;
    for (let r = 0; r < requests; r++) if (next() < rate) failed++;
    const time = [Math.floor(ofDay / 60), ofDay % 60]
      .map((x) => String(x).padStart(2, "0"))
      .join(":");
    minutes.push({ day, time, requests, failed });
  }
  return minutes;
}
