// مسار خادم: هذا الكود يعمل على الخادم فقط، ويجيب /api/products
export default defineEventHandler(() => getProducts());
