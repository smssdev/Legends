# Every route of the API, as Laravel sees it
$ php artisan route:list --path=api --except-vendor --json | jq -r -f ../routes.jq
GET|HEAD   api/products             ProductController@index
POST       api/products             ProductController@store
GET|HEAD   api/products/{product}   ProductController@show
PUT|PATCH  api/products/{product}   ProductController@update
DELETE     api/products/{product}   ProductController@destroy
GET|HEAD   api/user                 Closure
