# The trace, read from the bottom: the classes a request went through, in order
$ curl -s localhost:8000/api/products/9 | jq -r -f ../pipeline.jq
Illuminate\Http\Middleware\ValidatePathEncoding
Illuminate\Foundation\Http\Middleware\InvokeDeferredCallbacks
Illuminate\Http\Middleware\TrustProxies
Illuminate\Http\Middleware\HandleCors
Illuminate\Foundation\Http\Middleware\PreventRequestsDuringMaintenance
Illuminate\Http\Middleware\ValidatePostSize
Illuminate\Foundation\Http\Middleware\TrimStrings
Illuminate\Foundation\Http\Middleware\TransformsRequest
Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull
Illuminate\Routing\Middleware\ThrottleRequests
Illuminate\Routing\Middleware\SubstituteBindings
App\Http\Middleware\AddServerTiming
Illuminate\Routing\ControllerDispatcher
App\Http\Controllers\ProductController
