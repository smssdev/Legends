# Registering
$ curl -s -i localhost:3000/auth/register -H 'content-type: application/json' -d '{"email":"Lina@Example.com","name":"Lina","password":"a long and silly sentence"}'
HTTP/1.1 201 Created
content-type: application/json; charset=utf-8

{"id":4,"email":"lina@example.com","name":"Lina","role":"customer"}
# The same email again
$ curl -s localhost:3000/auth/register -H 'content-type: application/json' -d '{"email":"lina@example.com","name":"Lina","password":"another long sentence"}' | jq
{
  "title": "Email already registered",
  "status": 409,
  "instance": "/auth/register"
}
# A password that is too short
$ curl -s localhost:3000/auth/register -H 'content-type: application/json' -d '{"email":"sam@example.com","name":"Sam","password":"short"}' | jq
{
  "title": "Invalid body",
  "status": 422,
  "instance": "/auth/register",
  "errors": [
    {
      "field": "password",
      "message": "Too small: expected string to have >=12 characters"
    }
  ]
}
