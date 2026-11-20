<?php

// The shop's own settings.
// اقرأ البيئة هنا وحدها، وفي كل مكان آخر استخدم config('shop.…').
return [
    'currency' => env('SHOP_CURRENCY', 'EGP'),
    'requests_per_minute' => (int) env('SHOP_RATE_LIMIT', 60),
    'catalog_file' => storage_path('app/products.json'),
];
