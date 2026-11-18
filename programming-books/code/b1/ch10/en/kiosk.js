// Small functions, each with one job
function ticketPrice(age) {
  if (age < 4) return 0;
  if (age < 13 || age >= 65) return 6;
  return 10;
}

function applyMemberDay(price, isMember, day) {
  if (isMember && day === "Tuesday") {
    return price / 2;
  }
  return price;
}

function receiptLine(visitor) {
  const base = ticketPrice(visitor.age);
  const price = applyMemberDay(base, visitor.member, "Tuesday");
  return `${visitor.name}: ${price}`;
}

// Each visitor is an object; you will learn objects in Chapter 11.
const visitors = [
  { name: "Sara", age: 34, member: true },
  { name: "Adam", age: 9, member: false },
  { name: "Huda", age: 70, member: true },
];

for (const visitor of visitors) {
  console.log(receiptLine(visitor));
}
