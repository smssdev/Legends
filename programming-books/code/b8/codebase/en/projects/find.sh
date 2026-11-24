$ claude -p "where is the total of a receipt computed?" --model claude-opus-5-5 --no-session-persistence --tools Read,Bash --allowedTools "Bash(grep -rn total src)"
The total is computed in src/receipt.mjs, in receipt(): the amounts of the lines are added with reduce. Prices come from priceOf in src/menu.mjs.
