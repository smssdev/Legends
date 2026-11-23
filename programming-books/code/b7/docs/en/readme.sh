$ node readme.mjs
## Usage

Run the tool with:  
`node report.mjs [--date YYYY-MM-DD] [--vip] [--json]`

**Options:**  
- `--date YYYY-MM-DD`: Filter orders by date (default: today).  
- `--vip`: Show only VIP orders (default: false).  
- `--json`: Output results in JSON format (default: false).  

**Examples:**  
1. `node report.mjs --date 2026-11-20 --vip` → Shows VIP orders on that date.  
2. `node report.mjs --json` → Outputs order totals in JSON format.
--- options in the README
exists  --date
exists  --vip
exists  --json
