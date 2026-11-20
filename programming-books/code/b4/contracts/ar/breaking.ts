import { readFileSync } from "node:fs";
import { parse } from "yaml";

type Schema = {
  $ref?: string;
  required?: string[];
  properties?: Record<string, Schema>;
  enum?: string[];
};
const [before, after] = process.argv
  .slice(2)
  .map((f) => parse(readFileSync(f!, "utf8")));
const resolve = (doc: any, s: Schema = {}): Schema =>
  s.$ref ? doc.components.schemas[s.$ref.split("/").pop()!] : s;
const found: string[] = [];

// قارن كل عملية في النسخة القديمة بالجديدة
for (const [path, item] of Object.entries<any>(before.paths)) {
  for (const [method, op] of Object.entries<any>(item)) {
    const name = `${method.toUpperCase()} ${path}`;
    const next = after.paths[path]?.[method];
    if (!next) {
      found.push(`حُذف: ${name}`);
      continue;
    }
    // حقل لا يرسله العملاء القدامى، صار مطلوباً
    const oldIn = resolve(
      before,
      op.requestBody?.content["application/json"]?.schema,
    );
    const newIn = resolve(
      after,
      next.requestBody?.content["application/json"]?.schema,
    );
    for (const field of newIn.required ?? []) {
      if (!oldIn.required?.includes(field))
        found.push(`${name}: حقل جديد مطلوب في الطلب "${field}"`);
    }
    for (const [status, res] of Object.entries<any>(op.responses)) {
      const [type] = Object.keys(res.content ?? {});
      const oldOut = resolve(before, res.content?.[type!]?.schema);
      const newOut = resolve(
        after,
        next.responses[status]?.content?.[type!]?.schema,
      );
      for (const [field, schema] of Object.entries(oldOut.properties ?? {})) {
        // حقل يقرؤه العملاء القدامى، اختفى
        if (!newOut.properties?.[field])
          found.push(`${name} ${status}: حُذف حقل من الإجابة "${field}"`);
        // قيمة لم يرها العملاء القدامى قط
        const added = (newOut.properties?.[field]?.enum ?? []).filter(
          (v) => !schema.enum?.includes(v),
        );
        if (schema.enum && added.length)
          found.push(
            `${name} ${status}: "${field}" قيمة جديدة قد لا يعالجها العملاء: ${added.join(", ")}`,
          );
      }
    }
  }
}

console.log(found.length ? `${found.length} تغييرات كاسرة:` : "لا تغييرات كاسرة");
for (const line of found) console.log(`- ${line}`);
process.exitCode = found.length ? 1 : 0;
