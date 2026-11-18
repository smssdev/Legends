const students = [
  { name: "Mona", marks: [90, 85, 100] },
  { name: "Omar", marks: [70, 65, 80] },
  { name: "Sara", marks: [95, 92, 97] },
];

function average(marks) {
  const total = marks.reduce((sum, mark) => sum + mark, 0);
  return Math.round(total / marks.length);
}

let best = null;
for (const { name, marks } of students) {
  const avg = average(marks);
  console.log(name, "→", avg);
  if (best === null || avg > best.avg) best = { name, avg };
}
console.log("Top of the class:", best.name, "(" + best.avg + ")");
