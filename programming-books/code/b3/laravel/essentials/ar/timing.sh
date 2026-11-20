# كل جواب في الواجهة يحمل ترويسة الوسيط
$ curl -si localhost:8000/api/products/1 | grep -iE '^(server-timing|x-ratelimit)'
Server-Timing: app;dur=0.4
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 49
