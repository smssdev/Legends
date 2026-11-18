// 1. لعبة العد: Bit لمضاعفات 3، وBot لـ 5، وBit Bot للاثنين
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

// 2. مثلث من النجوم: حلقة داخل حلقة
for (let row = 1; row <= 4; row++) {
  let line = "";
  for (let i = 0; i < row; i++) {
    line += "* ";
  }
  console.log(line);
}
