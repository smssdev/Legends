function area(width, height) {
  return width * height;
}

function welcome(name, language = "ar") {
  if (language === "ar") {
    return `مرحباً يا ${name}`;
  }
  return `Welcome, ${name}`;
}

console.log(area(4, 5));
console.log(welcome("لينا"));
console.log(welcome("لينا", "en"));
