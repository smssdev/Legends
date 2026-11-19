# Not a number: the route does not even match
$ curl -s localhost:8000/api/products/abc | jq -c '{message, exception}'
{"message":"The route api/products/abc could not be found.","exception":"Symfony\\Component\\HttpKernel\\Exception\\NotFoundHttpException"}
