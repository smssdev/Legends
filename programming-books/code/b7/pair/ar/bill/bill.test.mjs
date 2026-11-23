import { splitBill } from './bill.mjs';

// اختبار الحالة العادية: فاتورة 1000، 3 أشخاص، 10% بقشيش
test('should split bill evenly with remainder to first people', () => {
  const result = splitBill(1000, 3, 10);
  assert.deepEqual(result, [367, 367, 366]);
});

// اختبار القسمة المتساوية (لا توجد بقية)
test('should split bill equally when divisible', () => {
  const result = splitBill(995, 2, 15);
  assert.deepEqual(result, [572, 572]);
});

// اختبار بقشيش صفر
test('should split bill with zero tip', () => {
  const result = splitBill(1000, 4, 0);
  assert.deepEqual(result, [250, 250, 250, 250]);
});

// اختبار خطأ عند عدد الأشخاص أقل من 1
test('should throw RangeError when people less than 1', () => {
  assert.throws(() => splitBill(1000, 0, 10), RangeError);
});
