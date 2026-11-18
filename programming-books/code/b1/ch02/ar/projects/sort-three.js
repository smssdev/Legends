let a = 12;
let b = 3;
let c = 7;

// ثلاث مقارنات تكفي لترتيب ثلاثة أرقام
if (a > b) [a, b] = [b, a];
if (b > c) [b, c] = [c, b];
if (a > b) [a, b] = [b, a];

console.log(a, b, c);
