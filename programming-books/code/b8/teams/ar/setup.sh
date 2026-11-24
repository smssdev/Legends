$ git init -q -b main && git add -A && git commit -qm "chore: start" && git switch -q -c feat/vat && cp changes/receipt-vat.mjs src/receipt.mjs && git commit -qam "feat(receipt): add 14% VAT" && git log --oneline main..HEAD
3c5635d feat(receipt): add 14% VAT
