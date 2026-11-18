function kmToMiles(km) {
  return km * 0.621371;
}

function kgToPounds(kg) {
  return kg * 2.20462;
}

function celsiusToFahrenheit(c) {
  return (c * 9) / 5 + 32;
}

function round(value, digits = 1) {
  return Number(value.toFixed(digits));
}

console.log("10 km =", round(kmToMiles(10)), "miles");
console.log("70 kg =", round(kgToPounds(70)), "pounds");
console.log("37 °C =", round(celsiusToFahrenheit(37)), "°F");
console.log("42.195 km =", round(kmToMiles(42.195), 2), "miles");
