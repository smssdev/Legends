let names = 1000000;
let steps = 0;

while (names > 1) {
  names = Math.ceil(names / 2);
  steps = steps + 1;
}

console.log(`Steps needed: ${steps}`);
