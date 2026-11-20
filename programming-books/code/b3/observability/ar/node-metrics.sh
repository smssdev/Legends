# المقاييس، كما يقرؤها Prometheus
$ curl -s localhost:3000/metrics | grep -E '^http_requests_total|duration_seconds_(bucket|sum).*products'
http_requests_total{method="GET",route="/products/:id",status="200"} 2
http_requests_total{method="GET",route="/products/:id",status="404"} 1
http_requests_total{method="GET",route="/boom",status="500"} 1
http_requests_total{method="GET",route="/checkout",status="200"} 1
http_request_duration_seconds_bucket{le="0.01",route="/products/:id"} 2
http_request_duration_seconds_bucket{le="0.05",route="/products/:id"} 3
http_request_duration_seconds_bucket{le="0.1",route="/products/:id"} 3
http_request_duration_seconds_bucket{le="0.5",route="/products/:id"} 3
http_request_duration_seconds_bucket{le="1",route="/products/:id"} 3
http_request_duration_seconds_bucket{le="+Inf",route="/products/:id"} 3
http_request_duration_seconds_sum{route="/products/:id"} 0.017403509999999872
