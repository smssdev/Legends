import { measure, rate } from "./measure-lib";

for (const page of ["slow.html", "fast.html"]) {
  const { lcp, cls } = await measure(page);
  // Rounded, because each run differs by a few milliseconds
  const seconds = (Math.round(lcp / 100) / 10).toFixed(1);
  console.log(`${page.padEnd(10)} LCP ${seconds} s (${rate(lcp, 2500, 4000)})   CLS ${cls.toFixed(2)} (${rate(cls, 0.1, 0.25)})`);
}
