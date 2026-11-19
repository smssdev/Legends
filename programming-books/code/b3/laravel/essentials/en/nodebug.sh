# The same with APP_DEBUG=false, as in production
$ curl -s localhost:8000/api/nothing
{
    "message": "The route api/nothing could not be found."
}
