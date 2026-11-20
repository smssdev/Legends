// القيم البسيطة تُنسخ
let a = 10;
let b = a;
b = 20;
console.log(a, b);

// الكائنات مشتركة: اسمان لكائن واحد
const original = { name: "سارة", tags: ["js"] };
const same = original;
same.name = "هدى";
console.log(original.name);

// النشر ينسخ المستوى الأول فقط
const shallow = { ...original };
shallow.tags.push("ts");
console.log(original.tags);

// structuredClone ينسخ كل المستويات
const deep = structuredClone(original);
deep.tags.push("react");
console.log(original.tags, deep.tags);
