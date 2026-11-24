$ claude -p "أين يُحسب إجمالي الإيصال؟" --model claude-opus-5-5 --no-session-persistence --tools Read,Bash --allowedTools "Bash(grep -rn total src)"
يُحسب الإجمالي في src/receipt.mjs، في receipt(): تُجمع مبالغ السطور بـ reduce. والأسعار تأتي من priceOf في src/menu.mjs.
