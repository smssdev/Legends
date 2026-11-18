const cards = [7, 3, 12, 5, 9];
let largest = cards[0];

for (const card of cards) {
  if (card > largest) {
    largest = card;
  }
}

console.log(`أكبر بطاقة هي ${largest}`);
