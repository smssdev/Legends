# عنوان مجهول و APP_DEBUG=true: انظر إلى كل ما يخبر به غريباً
$ curl -s localhost:8000/api/nothing | jq '{message, exception, file, line, trace: (.trace | length)}'
{
  "message": "The route api/nothing could not be found.",
  "exception": "Symfony\\Component\\HttpKernel\\Exception\\NotFoundHttpException",
  "file": "vendor/laravel/framework/src/Illuminate/Routing/AbstractRouteCollection.php",
  "line": 44,
  "trace": 30
}
