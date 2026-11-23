$ node readme.mjs
## Usage

Run the tool with:  
`node report.mjs [options]`

**Options:**  
`--date YYYY-MM-DD`  Set the order date (default: today).  
`--vip`              Show only VIP orders.  
`--json`             Output in JSON format.

**Examples:**  
`node report.mjs --date 2026-11-20` → Shows orders for that date.  
`node report.mjs --date 2026-11-20 --vip --json` → Shows only VIP orders in JSON.
--- options in the README
exists  --date
exists  --vip
exists  --json
