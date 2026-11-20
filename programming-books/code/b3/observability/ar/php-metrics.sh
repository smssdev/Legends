# المقاييس، كما يقرؤها Prometheus
$ curl -s localhost:8000/metrics | grep -E '^http_requests_total|duration_seconds_(bucket|sum).*products'
http_requests_total{method="GET",route="/products/:id",status="200"} 2
http_requests_total{method="GET",route="/products/:id",status="404"} 1
http_requests_total{method="GET",route="/boom",status="500"} 1
http_requests_total{method="GET",route="/stock/:id",status="200"} 1
http_requests_total{method="GET",route="/checkout",status="200"} 1
http_request_duration_seconds_bucket{route="/products/:id",le="0.01"} 3
http_request_duration_seconds_bucket{route="/products/:id",le="0.05"} 3
http_request_duration_seconds_bucket{route="/products/:id",le="0.1"} 3
http_request_duration_seconds_bucket{route="/products/:id",le="0.5"} 3
http_request_duration_seconds_bucket{route="/products/:id",le="1"} 3
http_request_duration_seconds_bucket{route="/products/:id",le="+Inf"} 3
http_request_duration_seconds_sum{route="/products/:id"} 0.01679348
