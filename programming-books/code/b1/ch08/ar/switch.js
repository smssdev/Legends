const size = "M";
let drink;

switch (size) {
  case "S":
    drink = 2;
    break;
  case "M":
    drink = 3;
    break;
  case "L":
    drink = 4;
    break;
  default:
    drink = 0;
}

console.log(`المشروب: ${drink}$`);
