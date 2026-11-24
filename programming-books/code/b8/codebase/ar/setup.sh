$ git init -q && git add -A && git -c user.name=Bit -c user.email=bit@example.com commit -qm start && git log --oneline && node --test 2>&1 | grep -E '^# (pass|fail)'
d9dd3cd start
# pass 1
# fail 0
