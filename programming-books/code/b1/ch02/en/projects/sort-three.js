let a = 12;
let b = 3;
let c = 7;

// Three comparisons are enough to sort three numbers
if (a > b) [a, b] = [b, a];
if (b > c) [b, c] = [c, b];
if (a > b) [a, b] = [b, a];

console.log(a, b, c);
