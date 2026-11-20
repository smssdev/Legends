const seconds = Number(process.argv[2] ?? 8);
const stats = Array.from({ length: seconds }, () => ({
  ok: 0,
  failed: 0,
  versions: new Set<string>(),
}));
const start = Date.now();

async function client() {
  for (;;) {
    const second = Math.floor((Date.now() - start) / 1000);
    if (second >= seconds) return;
    const row = stats[second]!;
    try {
      const response = await fetch("http://localhost:3000/");
      const body = await response.text();
      if (response.ok) {
        row.ok++;
        row.versions.add(body);
      } else row.failed++;
    } catch {
      row.failed++;
    }
  }
}

await Promise.all(Array.from({ length: 8 }, client));
// سطر كل ثانية: ما أُجيب، وما فشل، وأي النسخ أجابت
console.log("الثانية".padEnd(8), "نجح".padStart(5), "فشل".padStart(7), " النسخ");
stats.forEach((s, i) =>
  console.log(
    String(i + 1).padEnd(8),
    String(s.ok).padStart(5),
    String(s.failed).padStart(7),
    "",
    [...s.versions].sort().join(" "),
  ),
);
