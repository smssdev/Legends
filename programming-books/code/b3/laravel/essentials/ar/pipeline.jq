[.trace[].class // empty | select(test("Middleware|Controller"))]
| reverse
| reduce .[] as $c ([]; if index([$c]) then . else . + [$c] end)
| .[]
