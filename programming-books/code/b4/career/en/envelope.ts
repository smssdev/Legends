// what the interviewer gave, and what we assumed out loud
const salons = 50_000;
const bookingsPerSalonPerDay = 30;
// customers look at free slots about 20 times for each booking
const readsPerBooking = 20;
// traffic is not flat: the busiest hour has a fifth of the day
const busiestHourShare = 0.2;
// one booking row, with its indexes
const bytesPerBooking = 400;

const perDay = salons * bookingsPerSalonPerDay;
const avgWrites = perDay / 86_400;
const peakWrites = (perDay * busiestHourShare) / 3_600;
const peakReads = peakWrites * readsPerBooking;
const perYear = perDay * 365 * bytesPerBooking;

const n = (x: number) => Math.round(x).toLocaleString("en");
console.log(`${n(salons)} salons, ${n(perDay)} bookings a day`);
console.log(`average writes/s: ${n(avgWrites)}`);
console.log(`peak writes/s: ${n(peakWrites)}`);
console.log(`peak reads/s: ${n(peakReads)}`);
console.log(`data per year: ${(perYear / 1e9).toFixed(0)} GB`);
console.log(`=> fits one PostgreSQL primary with replicas for reads`);
