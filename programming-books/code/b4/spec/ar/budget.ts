// التوافر: كم توقفاً يسمح به كل هدف في شهر من 30 يوماً
const minutesPerMonth = 30 * 24 * 60;
console.log("الهدف".padEnd(9), "التوقف");
for (const target of [99, 99.5, 99.9, 99.95, 99.99]) {
  const down = minutesPerMonth * (1 - target / 100);
  console.log(`${target}%`.padEnd(9), `${down.toFixed(1)} دقيقة/شهر`);
}

// الحمل: من أرقام العمل في المواصفات إلى الطلبات في الثانية
const businesses = 2_000;
const bookingsPerDay = 25;
const pageViewsPerBooking = 12; // browsing, choosing, booking, the emails' links
const requestsPerPageView = 3; // the page, then the API calls it makes
const perDay = businesses * bookingsPerDay * pageViewsPerBooking * requestsPerPageView;
const average = perDay / 86_400;
console.log();
console.log(perDay.toLocaleString("en"), "طلب في اليوم");
console.log(average.toFixed(1), "المتوسط في الثانية");
console.log((average * 4).toFixed(1), "الذروة في الثانية (×4)");

// البيانات: كم يكبر جدول الحجوزات في سنة
const rowsPerYear = businesses * bookingsPerDay * 365;
const bytesPerRow = 200; // the columns, the row header, and the indexes
console.log();
console.log(rowsPerYear.toLocaleString("en"), "حجز في السنة");
console.log(`${((rowsPerYear * bytesPerRow) / 1024 ** 3).toFixed(1)} GB`, "حجم الجدول في سنة");
