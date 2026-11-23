$ node jsdoc.mjs
/**
 * Calculates the final price of a line item with a discount applied after the 10th unit.
 * @param {number} unit - The price per unit of the item.
 * @param {number} quantity - The number of units purchased.
 * @returns {number} The final price after applying the discount (at most 5000 off).
 * @example linePrice(100, 15) // => 1400
 * @example linePrice(50, 8) // => 400
 * @example linePrice(100, 10) // => 900
 */
--- the examples, run
FALSE linePrice(100, 15) // => 1400   (real: 1350)
true  linePrice(50, 8) // => 400   (real: 400)
true  linePrice(100, 10) // => 900   (real: 900)
