// Look for secrets before a prompt is sent anywhere.
const SECRET_PATTERNS = [
  ["API key", /\b(sk|pk|rk)-(live|test)?-?[A-Za-z0-9]{20,}\b/],
  ["AWS key", /\bAKIA[0-9A-Z]{16}\b/],
  ["private key", /-----BEGIN [A-Z ]*PRIVATE KEY-----/],
  ["password in a URL", /\/\/[^/\s:]+:[^@\s]+@/],
];

export function findSecrets(text) {
  return SECRET_PATTERNS.filter(([, pattern]) => pattern.test(text)).map(([name]) => name);
}

for (const prompt of ["Summarise the refund policy for a customer.", "Debug this: fetch(url, {headers: {Authorization: 'Bearer sk-live-4f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c'}})"]) {
  const found = findSecrets(prompt);
  console.log(`${found.length ? `BLOCKED (${found.join(", ")})` : "sent   "}  ${prompt.slice(0, 60)}`);
}
