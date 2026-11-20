# The same test, with Fastify's own error format
$ BUG=errors npm test
✖ answers 422 with a Problem when the email is invalid (…ms)
ℹ pass 3
ℹ fail 1
AssertionError [ERR_ASSERTION]: POST /bookings 400 is not in the contract
