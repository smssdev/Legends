// Only codes and links on the allow list may reach a customer.
const ALLOWED_CODES = ["WELCOME10"];
const ALLOWED_HOSTS = ["bitcafe.example"];

export function filterAnswer(answer) {
  const codes = (answer.match(/\b[A-Z]{3,}\d{2,}\b/g) ?? []).filter((c) => !ALLOWED_CODES.includes(c));
  const hosts = [...answer.matchAll(/https?:\/\/([^/\s]+)/g)]
    .map((m) => m[1])
    .filter((h) => !ALLOWED_HOSTS.includes(h));
  const problems = [...codes.map((c) => `code ${c}`), ...hosts.map((h) => `link to ${h}`)];
  return problems.length ? {ok: false, problems} : {ok: true};
}

for (const answer of [
  "New customers get 10% off with WELCOME10.",
  "Use FREE50 for 50% off!",
  "Order at https://bitcafe.example/menu.",
  "Claim your prize at https://bitcafe-prizes.example.net/win.",
]) {
  const {ok, problems} = filterAnswer(answer);
  console.log(`${ok ? "shown  " : "blocked"} ${answer}${ok ? "" : `  (${problems.join(", ")})`}`);
}
