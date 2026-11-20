// Primitives are copied
let a = 10;
let b = a;
b = 20;
console.log(a, b);

// Objects are shared: two names, one object
const original = { name: "Sara", tags: ["js"] };
const same = original;
same.name = "Huda";
console.log(original.name);

// Spread copies only the first level
const shallow = { ...original };
shallow.tags.push("ts");
console.log(original.tags);

// structuredClone copies every level
const deep = structuredClone(original);
deep.tags.push("react");
console.log(original.tags, deep.tags);
