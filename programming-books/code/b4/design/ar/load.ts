import autocannon from "autocannon";

const [url, ...levels] = process.argv.slice(2);
console.log(
  "العملاء".padEnd(9),
  "طلب/ث".padStart(11),
  "p50 ms".padStart(8),
  "p99 ms".padStart(8),
);
// الحمل نفسه عند كل مستوى تزامن: 5 ثوانٍ، ثم الإنتاجية وزمن الاستجابة
for (const connections of levels.map(Number)) {
  const result = await autocannon({ url: url!, connections, duration: 5 });
  console.log(
    String(connections).padEnd(9),
    String(Math.round(result.requests.average)).padStart(11),
    String(result.latency.p50).padStart(8),
    String(result.latency.p99).padStart(8),
  );
}
