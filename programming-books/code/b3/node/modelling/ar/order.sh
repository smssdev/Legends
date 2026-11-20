# استعلام بأنواع: طلب مع عميله وعناصره
$ node --env-file=.env demos/order.ts
{
  id: 2,
  status: 'shipped',
  customer: 'سارة',
  items: [
    { name: 'عدة الروبوت', quantity: 1, price: 45000 },
    { name: 'عجلات احتياطية', quantity: 1, price: 6000 },
    { name: 'حزمة بطارية', quantity: 1, price: 12500 }
  ]
}
