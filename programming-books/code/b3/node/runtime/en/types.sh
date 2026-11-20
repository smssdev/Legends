# Node runs the TypeScript file: the types are removed, nothing is checked
$ node demos/strip.ts
45050
# An enum is not just a type: it needs code, so plain Node refuses it
$ node demos/enum.ts 2>&1 | grep SyntaxError
SyntaxError [ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX]: TypeScript enum is not supported in strip-only mode
# tsc checks the types (and, with erasableSyntaxOnly, refuses the enum too)
$ npx tsc
demos/enum.ts(1,6): error TS1294: This syntax is not allowed when 'erasableSyntaxOnly' is enabled.
demos/strip.ts(4,31): error TS2322: Type 'string' is not assignable to type 'number'.
