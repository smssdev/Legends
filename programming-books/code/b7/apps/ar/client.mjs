// Asks the service, printing the answer as it streams, with the time to
// the first piece.
const question = process.argv[2];
const start = performance.now();
const response = await fetch(`http://localhost:8765/?q=${encodeURIComponent(question)}`);
let first = 0;
let text = "";
for await (const chunk of response.body) {
  first ||= performance.now() - start;
  text += new TextDecoder().decode(chunk);
}
const total = performance.now() - start;
console.log(text.trim());
console.log(`--- first piece after ${(first / 1000).toFixed(1)} s, whole answer after ${(total / 1000).toFixed(1)} s`);
