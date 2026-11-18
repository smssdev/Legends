function hasDigit(text) {
  for (const char of text) {
    if ("0123456789".includes(char)) return true;
  }
  return false;
}

function hasUpper(text) {
  return text !== text.toLowerCase();
}

function strength(password) {
  let points = 0;
  if (password.length >= 8) points++;
  if (password.length >= 12) points++;
  if (hasDigit(password)) points++;
  if (hasUpper(password)) points++;

  if (points <= 1) return "ضعيفة";
  if (points <= 3) return "مقبولة";
  return "قوية";
}

for (const password of ["cat", "sunshine", "sunshine2026", "Sunshine2026Blue"]) {
  console.log(password, "→", strength(password));
}
