$ node jsdoc.mjs
/**
 * Calculates the final price of a line item with a 10% discount on cups from the 10th cup, capped at a maximum discount of 5000.
 * @param {number} unit - The price per unit of the item.
 * @param {number} quantity - The number of units being purchased; must be at least 1.
 * @returns {number} The final price after applying the discount (at most 5000 off).
 * @example linePrice(10, 5) // => 50
 * @example linePrice(10, 10) // => 90
 * @example linePrice(10, 20) // => 180
 */

--- the examples, run
true  linePrice(10, 5) // => 50   (real: 50)
true  linePrice(10, 10) // => 90   (real: 90)
true  linePrice(10, 20) // => 180   (real: 180)
