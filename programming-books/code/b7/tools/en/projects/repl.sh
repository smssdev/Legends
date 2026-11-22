$ printf 'How do I read a file line by line in Node?\nAnd in reverse order?\n/reset\nAnd in reverse order?\n' | node repl.mjs
> How do I read a file line by line in Node?
Use `fs.createReadStream()` with a `on('data')` event listener to read a file line by line.  
Example: `fs.createReadStream('file.txt').on('data', (chunk) => { /* process line */ });`

> And in reverse order?
You can't easily read a file in reverse order with `fs.createReadStream()` since it's stream-based and reads sequentially.  
Instead, read all lines into memory first (e.g., with `fs.readFileSync()`), then reverse the array and process line by line.

> /reset
(conversation reset)

> And in reverse order?
Sure! Just reverse the order of elements in an array or string. For example:  
`[1, 2, 3].reverse()` → `[3, 2, 1]`.
