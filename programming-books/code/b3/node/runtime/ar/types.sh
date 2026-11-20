# يشغّل Node ملف TypeScript: تُحذف الأنواع، ولا يُفحص شيء
$ node demos/strip.ts
45050
# التعداد enum ليس نوعاً فقط: يحتاج كوداً، فيرفضه Node وحده
$ node demos/enum.ts 2>&1 | grep SyntaxError
SyntaxError [ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX]: TypeScript enum is not supported in strip-only mode
# يفحص tsc الأنواع (ومع erasableSyntaxOnly يرفض التعداد أيضاً)
$ npx tsc
demos/enum.ts(1,6): error TS1294: This syntax is not allowed when 'erasableSyntaxOnly' is enabled.
demos/strip.ts(4,31): error TS2322: Type 'string' is not assignable to type 'number'.
