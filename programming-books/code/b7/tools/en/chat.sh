$ node chat.mjs
> How do I read a JSON file in Node?
Use `fs.readFileSync()` to read the file and `JSON.parse()` to parse it:  
`const data = JSON.parse(fs.readFileSync('file.json', 'utf8'));`
[75 tokens]

> And how do I write one?
Use `fs.writeFileSync()` to write JSON data:  
`fs.writeFileSync('file.json', JSON.stringify(data, null, 2));`
[120 tokens]

A new conversation, asked only the second question:
> And how do I write one?
Use `const myVariable = value;` to declare a variable.  
For functions, use `function name() { /* code */ }` or `const name = () => { /* code */ }`.
