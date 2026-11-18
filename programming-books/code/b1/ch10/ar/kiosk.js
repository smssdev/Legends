// دوال صغيرة، لكل واحدة وظيفة واحدة
function ticketPrice(age) {
  if (age < 4) return 0;
  if (age < 13 || age >= 65) return 6;
  return 10;
}

function applyMemberDay(price, isMember, day) {
  if (isMember && day === "الثلاثاء") {
    return price / 2;
  }
  return price;
}

function receiptLine(visitor) {
  const base = ticketPrice(visitor.age);
  const price = applyMemberDay(base, visitor.member, "الثلاثاء");
  return `${visitor.name}: ${price}`;
}

// كل زائر كائن، وستتعلم الكائنات في الفصل 11.
const visitors = [
  { name: "سارة", age: 34, member: true },
  { name: "آدم", age: 9, member: false },
  { name: "هدى", age: 70, member: true },
];

for (const visitor of visitors) {
  console.log(receiptLine(visitor));
}
