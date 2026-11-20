# A public file
$ curl -s localhost:3000/unsafe/files/terms.txt
Terms of sale: prices include VAT; returns within 14 days.
# Climbing out of the folder
$ curl -s --path-as-is localhost:3000/unsafe/files/../.env
DATABASE_URL=postgres://bit:secret@localhost:5432/shop
ALLOWED_ORIGIN=https://shop.example
# The same path, on the safe route
$ curl -s --path-as-is localhost:3000/files/../.env | jq -c
{"title":"Not found","status":404}
