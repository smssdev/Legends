const year = 2028;
const month = 2;

// السنة الكبيسة: كل 4 سنوات، إلا كل 100، إلا كل 400
const isLeap = (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;

let days;
switch (month) {
  case 2:
    days = isLeap ? 29 : 28;
    break;
  case 4:
  case 6:
  case 9:
  case 11:
    days = 30;
    break;
  default:
    days = 31;
}

console.log(`هل ${year} سنة كبيسة؟ ${isLeap}`);
console.log(`الشهر ${month} من ${year} فيه ${days} يوماً`);
