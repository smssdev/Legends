// 62 characters that are safe in any URL
const ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

export function encode(n: bigint): string {
  let code = "";
  do {
    code = ALPHABET[Number(n % 62n)] + code;
    n /= 62n;
  } while (n > 0n);
  return code;
}

export function decode(code: string): bigint {
  let n = 0n;
  for (const char of code) n = n * 62n + BigInt(ALPHABET.indexOf(char));
  return n;
}

for (const id of [1n, 61n, 62n, 3_843n, 1_000_000n, 56_800_235_583n]) {
  const code = encode(id);
  console.log(
    String(id).padStart(12),
    "→",
    code.padEnd(7),
    "→",
    String(decode(code)),
  );
}
