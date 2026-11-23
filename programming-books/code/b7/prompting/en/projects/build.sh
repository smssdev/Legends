$ node build.mjs
[system] You are a senior JavaScript developer who reviews code for a small team.
The team writes Node 22 code with ES modules and no TypeScript.

Explain what this line does: const unique = [...new Set(items)];

One sentence, then one example with input and output.

Do not suggest other ways to write it.
---
This line creates a new array with only unique values by converting the input array to a Set (which removes duplicates) and then spreading it back into an array.  

Example:  
Input: `[1, 2, 2, 3, 3, 4]`  
Output: `[1, 2, 3, 4]`
