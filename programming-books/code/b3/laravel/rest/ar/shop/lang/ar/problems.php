<?php

// The texts of the API's problems.
// __('problems.stale') reads them in the app's language.
return [
    'invalid' => 'طلب غير صالح',
    'not_found' => 'غير موجود',
    'no_product' => 'لا يوجد منتج رقمه :id.',
    'no_order' => 'لا يوجد طلب رقمه :id.',
    'nothing' => 'لا شيء هنا.',
    'precondition' => 'شرط مسبق مطلوب',
    'need_if_match' => 'أرسل If-Match مع آخر ETag قرأته.',
    'stale' => 'تغيّر المنتج',
    'stale_detail' => 'غيّره أحد بعد أن قرأته. اقرأه من جديد.',
    'key' => 'الترويسة Idempotency-Key مطلوبة: من 8 إلى 100 حرف.',
    'reused' => 'مفتاح عدم التكرار مستخدم',
    'reused_detail' => 'استُخدم هذا المفتاح مع محتوى مختلف.',
    'in_progress' => 'الطلب قيد التنفيذ',
    'in_progress_detail' => 'ما زال طلب بهذا المفتاح يعمل.',
    'stock' => 'المخزون لا يكفي',
    'stock_detail' => 'بقي :stock فقط من المنتج :id.',
    'state' => 'لا يمكن إلغاء الطلب',
    'state_detail' => 'الطلب :id حالته :status من قبل.',
    'limit' => 'طلبات كثيرة جداً',
    'server' => 'خطأ في الخادم',
];
