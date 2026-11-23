$ node map.mjs
- `legacy/data/orders.json`: Stores order data with customer type and line items.  
- `legacy/index.js`: Runs the nightly job to load orders and generate a report.  
- `legacy/lib/calc.js`: Calculates order total with VIP discount and optional tax reduction.  
- `legacy/lib/report.js`: Formats and outputs a human-readable report from order data.  
- `legacy/lib/store.js`: Reads and parses JSON files safely.  

**File that runs first**: `legacy/index.js` — it starts the process by loading the orders and generating the report.
