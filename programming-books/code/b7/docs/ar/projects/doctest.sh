$ node doctest.mjs changed/price.mjs
pass linePrice(1000, 9) // => 9000
FAIL linePrice(1000, 10) // => 9000   (real: 10000)
FAIL linePrice(6000, 10) // => 55000   (real: 60000)
1 of 3 examples hold
