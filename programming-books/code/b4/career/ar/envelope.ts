// ما أعطاه المقابِل، وما افترضناه بصوت عالٍ
const salons = 50_000;
const bookingsPerSalonPerDay = 30;
// ينظر الزبائن في المواعيد الفارغة نحو 20 مرة لكل حجز
const readsPerBooking = 20;
// الحركة ليست مستوية: أزحم ساعة تحمل نحو خُمس اليوم
const busiestHourShare = 0.2;
// صف حجز واحد، بفهارسه
const bytesPerBooking = 400;

const perDay = salons * bookingsPerSalonPerDay;
const avgWrites = perDay / 86_400;
const peakWrites = (perDay * busiestHourShare) / 3_600;
const peakReads = peakWrites * readsPerBooking;
const perYear = perDay * 365 * bytesPerBooking;

const n = (x: number) => Math.round(x).toLocaleString("en");
console.log(`${n(salons)} صالون, ${n(perDay)} حجز في اليوم`);
console.log(`متوسط الكتابة/ث: ${n(avgWrites)}`);
console.log(`ذروة الكتابة/ث: ${n(peakWrites)}`);
console.log(`ذروة القراءة/ث: ${n(peakReads)}`);
console.log(`البيانات في السنة: ${(perYear / 1e9).toFixed(0)} GB`);
console.log(`=> يكفيه PostgreSQL رئيسي واحد مع نسخ للقراءة`);
