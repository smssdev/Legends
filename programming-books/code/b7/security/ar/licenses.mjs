import fs from "node:fs";
import {readGgufFileInfo, resolveModelFile} from "node-llama-cpp";
import {MODEL} from "./lib/model.mjs";

// كل ملف نموذج يقول رخصته؛ اقرأها، ولا تفترضها.
for (const name of [MODEL, "hf:Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0"]) {
  const info = await readGgufFileInfo(await resolveModelFile(name));
  const {general} = info.metadata;
  console.log(`${general.name.padEnd(28)} license: ${general.license ?? "(not stated in the file)"}`);
}
const pkg = JSON.parse(fs.readFileSync("node_modules/node-llama-cpp/package.json", "utf8"));
console.log(`${("node-llama-cpp " + pkg.version).padEnd(28)} license: ${pkg.license}`);
