String strength(String password, {int minLength = 8}) {
  var digits = 0, upper = 0, lower = 0, other = 0;
  // انظر إلى كل حرف مرة واحدة، وعُدّ ما نحتاجه.
  for (var ch in password.split('')) {
    if ('0123456789'.contains(ch)) {
      digits++;
    } else if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
      upper++;
    } else if (ch.toLowerCase() == ch && ch.toUpperCase() != ch) {
      lower++;
    } else {
      other++;
    }
  }
  // نقطة لكل شيء موجود في كلمة المرور.
  var points = 0;
  if (password.length >= minLength) points++;
  if (digits > 0) points++;
  if (upper > 0 && lower > 0) points++;
  if (other > 0) points++;
  return switch (points) {
    4 => 'قوية',
    2 || 3 => 'مقبولة',
    _ => 'ضعيفة',
  };
}

void main() {
  for (var p in ['cairo', 'cairo2026', 'Cairo2026', 'Cairo#2026', 'Ab#1']) {
    print('${p.padRight(12)} ${strength(p)}');
  }
  print('Ab#1 (minLength: 4) ${strength('Ab#1', minLength: 4)}');
}
