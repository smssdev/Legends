# A typed query: an order with its customer and items
$ node --env-file=.env demos/order.ts
{
  id: 2,
  status: 'shipped',
  customer: 'Sara',
  items: [
    { name: 'Robot kit', quantity: 1, price: 45000 },
    { name: 'Spare wheels', quantity: 1, price: 6000 },
    { name: 'Battery pack', quantity: 1, price: 12500 }
  ]
}
