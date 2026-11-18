// شبّاك التذاكر: غيّر هذه القيم وشغّل البرنامج من جديد.
const age = 34;
const isMember = true;
const day = "الثلاثاء";
const showTime = 22; // بنظام 24 ساعة

let price;
if (age < 4) {
  price = 0;
} else if (age < 13 || age >= 65) {
  price = 6;
} else {
  price = 10;
}

if (isMember && day === "الثلاثاء") {
  price = price / 2;
}

if (showTime >= 22 && price > 0) {
  price = price - 1;
}

const message = price === 0 ? "الدخول مجاني" : `ادفع ${price}$ من فضلك`;
console.log(message);
