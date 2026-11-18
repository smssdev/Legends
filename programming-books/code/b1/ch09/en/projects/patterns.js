// 1. The counting game: Bit for multiples of 3, Bot for 5, Bit Bot for both
for (let n = 1; n <= 15; n++) {
  if (n % 3 === 0 && n % 5 === 0) {
    console.log("Bit Bot");
  } else if (n % 3 === 0) {
    console.log("Bit");
  } else if (n % 5 === 0) {
    console.log("Bot");
  } else {
    console.log(n);
  }
}

// 2. A triangle of stars: a loop inside a loop
for (let row = 1; row <= 4; row++) {
  let line = "";
  for (let i = 0; i < row; i++) {
    line += "* ";
  }
  console.log(line);
}
