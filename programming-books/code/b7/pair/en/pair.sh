$ node pair.mjs
== plan
1. Validate input: throw a RangeError if people is less than 1.  
2. Calculate the tip as total * tipPercent / 100, rounded to the nearest piastre.  
3. Compute the total amount to split (total + tip).  
4. Divide the total amount among people, assigning the first person an extra piastre if the division is not even.  
5. Return the array of individual amounts.
== tests: bill/bill.test.mjs, 6 tests
== tests against an empty splitBill: 0 passed, 6 failed
   they fail on their assertions: good
== round 1: 6 passed, 0 failed
