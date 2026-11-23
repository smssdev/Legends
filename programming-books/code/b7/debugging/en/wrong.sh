$ node wrong.mjs
**Most likely cause:** The function incorrectly assumes that each price appears only once, and `find()` may return the wrong drink if multiple drinks share the same price, or it fails to properly match the drink by price due to the order of iteration.

**Fixed function:**
```javascript
export function topThree(menu) {
  return menu
    .sort((a, b) => b.price - a.price)
    .slice(0, 3)
    .map(drink => drink.name);
}
```

--- run:
before: [ 'cold brew', 'latte', 'espresso' ]
fixed:  ["mocha","cold brew","latte"]
right:  ["mocha","cold brew","latte"]
