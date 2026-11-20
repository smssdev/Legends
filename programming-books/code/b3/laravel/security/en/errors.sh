# A search of 200 characters
$ curl -s -G localhost:8000/api/products -H 'Accept: application/json' --data-urlencode "q=$(printf 'a%.0s' $(seq 200))" | jq -c
{"message":"The q field must not be greater than 100 characters.","errors":{"q":["The q field must not be greater than 100 characters."]}}
# The same error with APP_DEBUG=false
$ curl -s localhost:8000/api/boom -H 'Accept: application/json' | jq -c
{"message":"Server Error"}
