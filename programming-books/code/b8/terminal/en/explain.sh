$ claude -p "Explain price.mjs in two sentences." --model claude-opus-5-5 --no-session-persistence
price.mjs exports total(bill, tip), which adds the tip percentage to the bill. It reads the bill with parseInt, so the piastres of a bill like 85.50 are dropped.
