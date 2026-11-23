$ node summary.mjs legacy
legacy/index.js: This file runs a nightly job that loads order data from a JSON file and generates a report, logging the result to the console.
legacy/lib/calc.js: This file defines a `calc` function that computes a weighted sum of values from an object's `l` array, with optional discounts for large results or VIP status, and returns a non-negative value.
legacy/lib/report.js: This file exports a `make` function that takes an array of orders and a discount value, calculates the total for each order using a calculator module, formats the results as a newline-separated string with line items and a final total, all in a currency-friendly format.
legacy/lib/store.js: This file exports a function `load` that reads a JSON file asynchronously and parses its contents, returning an error if the file fails to read or is not valid JSON.
