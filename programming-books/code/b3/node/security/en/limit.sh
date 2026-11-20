# A body of 200 KB
$ head -c 200000 /dev/zero | tr '\0' 'a' | sed 's/.*/{"name":"&"}/' | curl -s -X PATCH localhost:3000/users/2 -H 'content-type: application/json' --data-binary @- | jq -c
{"title":"Body too large","status":413}
