// availability: how much downtime each target allows in a 30-day month
const minutesPerMonth = 30 * 24 * 60;
console.log("target".padEnd(9), "downtime");
for (const target of [99, 99.5, 99.9, 99.95, 99.99]) {
  const down = minutesPerMonth * (1 - target / 100);
  console.log(`${target}%`.padEnd(9), `${down.toFixed(1)} min/month`);
}

// load: from the business numbers in the spec to requests per second
const businesses = 2_000;
const bookingsPerDay = 25;
const pageViewsPerBooking = 12; // browsing, choosing, booking, the emails' links
const requestsPerPageView = 3; // the page, then the API calls it makes
const perDay = businesses * bookingsPerDay * pageViewsPerBooking * requestsPerPageView;
const average = perDay / 86_400;
console.log();
console.log(perDay.toLocaleString("en"), "requests a day");
console.log(average.toFixed(1), "average per second");
console.log((average * 4).toFixed(1), "peak per second (x4)");

// data: how much the bookings table grows in a year
const rowsPerYear = businesses * bookingsPerDay * 365;
const bytesPerRow = 200; // the columns, the row header, and the indexes
console.log();
console.log(rowsPerYear.toLocaleString("en"), "bookings a year");
console.log(`${((rowsPerYear * bytesPerRow) / 1024 ** 3).toFixed(1)} GB`, "table size a year");
