$ node explain.mjs
Sure! Here's a simple, plain explanation of what the `calc` function does — written in plain English, like a café manager would understand:

- **Step 1: Add up the total value of all items sold**  
  The function looks at each item in the list (like drinks, food, or desserts) and multiplies the price of each item by how many of that item were sold. Then it adds all those amounts together to get a total value.

- **Step 2: Apply a discount if the total is over $20,000**  
  If the total value of all sales is more than $20,000, then the function takes away 10% of that total (like a big discount for high-volume days).

- **Step 3: Give a special discount for VIP customers**  
  If the customer group is marked as "VIP", then the function subtracts an extra $500 from the total — like a bonus for loyal customers.

- **Step 4: Make sure the final amount is not negative**  
  If after all the calculations the total comes out negative (which shouldn’t happen), the function just returns zero — because you can’t have a negative amount of money.

In short:  
👉 Add up all sales.  
👉 If sales are high, give a 10% discount.  
👉 If it’s a VIP customer, give an extra $500 off.  
👉 Never let the total go below zero.
