function area(width, height) {
  return width * height;
}

function welcome(name, language = "en") {
  if (language === "ar") {
    return `مرحباً يا ${name}`;
  }
  return `Welcome, ${name}`;
}

console.log(area(4, 5));
console.log(welcome("Lina"));
console.log(welcome("Lina", "ar"));
