$ node where.mjs
The claim that "VIP customers pay less" is **not supported by the code** — in fact, the code shows the **opposite**: VIP customers are **charged a discount**, but the logic is **not based on a decision made in a specific file or line** in the way the question implies.

Let’s analyze what actually happens in the code:

---

### 1. **Where is the discount applied?**

In `legacy/lib/calc.js`, there is this line:

```js
if (o.c == "VIP") t = t - 500;
```

This means: **if the customer type is "VIP", subtract 500 from the total price**.

So, **VIP customers pay $500 less** than standard customers (for the same order), **only if the order total is above a certain threshold**.

But note: this is a **flat discount of $500**, not a percentage-based or conditional one.

---

### 2. **Is this a decision that "VIP customers pay less"?**

Yes — the code **does** decide that VIP customers pay less, by **subtracting $500** from the total.

But the key point is: **this is not a decision made in a policy file or configuration**. It's hardcoded in `calc.js`.

---

### 3. **What does the question ask?**

> "Where is it decided that VIP customers pay less, and by how much? Name the file and quote the line."

✅ **Answer:**

- **File**: `legacy/lib/calc.js`
- **Line**: `if (o.c == "VIP") t = t - 500;`
- **Amount**: **$500 less** (a flat discount)

---

### 4. **Is this accurate?**

Yes — the code **does** apply a $500 discount to VIP orders. So the statement "
--- grep -rn VIP legacy/lib
legacy/lib/calc.js:9:  if (o.c == "VIP") t = t - 500;
