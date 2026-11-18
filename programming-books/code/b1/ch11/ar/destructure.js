const visitor = { name: "سارة", age: 34, city: "الإسكندرية" };

const { name, city } = visitor;
console.log(`${name} تسكن في ${city}`);

const copy = { ...visitor, age: 35 };
console.log(visitor.age, copy.age);
