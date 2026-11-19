# ليس رقماً: المسار لا يطابق أصلاً
$ curl -s localhost:8000/api/products/abc | jq -c '{message, exception}'
{"message":"The route api/products/abc could not be found.","exception":"Symfony\\Component\\HttpKernel\\Exception\\NotFoundHttpException"}
