$ node shop/report.mjs 2>&1 | grep -v node:internal
order 41: 900
file://shop/orders.mjs:5
  return drink.price;
               ^

TypeError: Cannot read properties of undefined (reading 'price')
    at priceOf (file://shop/orders.mjs:5:16)
    at file://shop/orders.mjs:9:50
    at Array.reduce (<anonymous>)
    at total (file://shop/orders.mjs:9:22)
    at file://shop/report.mjs:10:37

Node.js v22.23.5
