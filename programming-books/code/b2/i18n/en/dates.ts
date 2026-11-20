const date = new Date(Date.UTC(2026, 2, 20, 14, 30));
const fmt = (locale: string, options: Intl.DateTimeFormatOptions) =>
  console.log(locale.padEnd(26), new Intl.DateTimeFormat(locale, { timeZone: "Africa/Cairo", ...options }).format(date));

fmt("en-GB", { dateStyle: "full", timeStyle: "short" });
fmt("en-US", { dateStyle: "full", timeStyle: "short" });
fmt("ar-EG", { dateStyle: "full", timeStyle: "short" });
fmt("ar-SA-u-ca-islamic-umalqura", { dateStyle: "long" });

const rtf = new Intl.RelativeTimeFormat("ar", { numeric: "auto" });
console.log([-1, 0, 1, 2, 3, 11].map((d) => rtf.format(d, "day")).join(" | "));
console.log(new Intl.ListFormat("ar", { type: "conjunction" }).format(["HTML", "CSS", "JavaScript"]));
