import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { gzipSync } from "node:zlib";

// يُفشل البناء حين تكبر JavaScript أو CSS المرسلة للمستخدمين فوق الميزانية
const BUDGET = { js: 60 * 1024, css: 15 * 1024 };

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? files(path) : [path];
  });
}

const sizes = { js: 0, css: 0 };
for (const file of files(process.argv[2] ?? "../../../vendor")) {
  const kind = file.endsWith(".js") ? "js" : file.endsWith(".css") ? "css" : null;
  if (kind) sizes[kind] += gzipSync(readFileSync(file)).length;
}

let failed = false;
for (const kind of ["js", "css"] as const) {
  const over = sizes[kind] > BUDGET[kind];
  failed ||= over;
  const kb = (n: number) => `${(n / 1024).toFixed(1)} KB`;
  console.log(`${kind.toUpperCase().padEnd(4)} ${kb(sizes[kind]).padStart(9)}  الميزانية ${kb(BUDGET[kind]).padStart(8)}  ${over ? "✗ تجاوز الميزانية" : "✓ ضمن الميزانية"}`);
}
process.exitCode = failed ? 1 : 0;
