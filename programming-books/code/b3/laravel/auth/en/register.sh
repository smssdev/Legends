# Registering
$ curl -s -i localhost:8000/api/auth/register -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"Lina@Example.com","name":"Lina","password":"a long and silly sentence"}'
HTTP/1.1 201 Created
Content-Type: application/json
{"id":4,"email":"lina@example.com","name":"Lina","role":"customer"}
# The same email again
$ curl -s localhost:8000/api/auth/register -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"lina@example.com","name":"Lina","password":"another long sentence"}' | jq
{
  "message": "The email has already been taken.",
  "errors": {
    "email": [
      "The email has already been taken."
    ]
  }
}
# A password that is too short
$ curl -s localhost:8000/api/auth/register -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"email":"sam@example.com","name":"Sam","password":"short"}' | jq
{
  "message": "The password field must be at least 12 characters.",
  "errors": {
    "password": [
      "The password field must be at least 12 characters."
    ]
  }
}
