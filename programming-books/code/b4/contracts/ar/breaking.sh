# ما الذي سينكسر لو نشرنا النسخة التالية
$ node breaking.ts openapi.yaml openapi.next.yaml
3 تغييرات كاسرة:
- POST /bookings: حقل جديد مطلوب في الطلب "phone"
- POST /bookings 201: حُذف حقل من الإجابة "ends_at"
- POST /bookings 201: "status" قيمة جديدة قد لا يعالجها العملاء: no_show
