# الشيء نفسه مع APP_DEBUG=false، كما في الإنتاج
$ curl -s localhost:8000/api/nothing
{
    "message": "The route api/nothing could not be found."
}
