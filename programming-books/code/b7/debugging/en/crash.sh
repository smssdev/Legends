$ node crash.mjs
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

--- the model:
The error occurs because `drink` is undefined when `MENU.find()` does not find a matching drink name, and the code attempts to access `drink.price`, which causes a "Cannot read properties of undefined (reading 'price')" error. This happens when an item name in `order.items` does not exist in the MENU array.

BUG AT file:orders.mjs:5

named: (none)
the crash: shop/orders.mjs:5 (drink is undefined)
the cause: shop/report.mjs:5 (a drink that is not on the menu)
