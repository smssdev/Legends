# ملف عام
$ curl -s localhost:3000/unsafe/files/terms.txt
شروط البيع: الأسعار تشمل الضريبة؛ والإرجاع خلال 14 يوماً.
# الصعود خارج المجلد
$ curl -s --path-as-is localhost:3000/unsafe/files/../.env
DATABASE_URL=postgres://bit:secret@localhost:5432/shop
ALLOWED_ORIGIN=https://shop.example
# المسار نفسه، على المسار الآمن
$ curl -s --path-as-is localhost:3000/files/../.env | jq -c
{"title":"غير موجود","status":404}
