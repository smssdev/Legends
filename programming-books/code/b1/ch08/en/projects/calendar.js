const year = 2028;
const month = 2;

// Leap years: every 4 years, except every 100, except every 400
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

console.log(`${year} is a leap year: ${isLeap}`);
console.log(`Month ${month} of ${year} has ${days} days`);
