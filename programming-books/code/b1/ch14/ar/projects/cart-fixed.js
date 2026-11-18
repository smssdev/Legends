// الأسعار تصل نصوصاً، كما تصل من نموذج أو ملف
const prices = ["120", "45", "35"];
const discount = 20;

function total(list) {
  let sum = 0;
  for (let i = 0; i < list.length; i++) {
    sum = sum + Number(list[i]);
  }
  return sum;
}

const before = total(prices);
console.log("المجموع:", before);
console.log("بعد الخصم:", before - discount);
