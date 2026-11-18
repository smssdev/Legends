const visitor = { name: "Sara", age: 34, city: "Alexandria" };

const { name, city } = visitor;
console.log(`${name} lives in ${city}`);

const copy = { ...visitor, age: 35 };
console.log(visitor.age, copy.age);
