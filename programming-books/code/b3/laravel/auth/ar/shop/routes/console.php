<?php

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Hash;

Artisan::command('shop:hash', function () {
    $password = 'correct horse battery staple';
    $a = Hash::make($password);
    $b = Hash::make($password);
    $this->line("التجزئة 1 $a");
    $this->line("التجزئة 2 $b");
    $this->line('كلمة المرور الصحيحة: '.json_encode(Hash::check($password, $a)));
    $this->line('كلمة مرور خطأ: '.json_encode(Hash::check($password.'r', $a)));
    $start = hrtime(true);
    Hash::make($password);
    $this->line('استغرقت التجزئة الواحدة '.round((hrtime(true) - $start) / 1e6).' ms');
});

Artisan::command('shop:rehash', function () {
    // التمرين 3: تجزئة صُنعت بجولات أقل مما يطلبه الإعداد
    $old = Hash::make('correct horse battery staple', ['rounds' => 10]);
    $this->line('تحتاج إعادة تجزئة (10 جولات): '.json_encode(Hash::needsRehash($old)));
    $new = Hash::make('correct horse battery staple');
    $this->line('تحتاج إعادة تجزئة (12 جولة): '.json_encode(Hash::needsRehash($new)));
});

Artisan::command('shop:jwt', function () {
    $secret = 'a secret only the server knows';
    $url = fn (string $bytes) => rtrim(strtr(base64_encode($bytes), '+/', '-_'), '=');
    $b64 = fn (array $value) => $url(json_encode($value));
    $sign = fn (string $data) => $url(hash_hmac('sha256', $data, $secret, true));

    // JWT: الرأس والحمولة بـ base64url، ثم HMAC لهما بسر الخادم
    $header = $b64(['alg' => 'HS256', 'typ' => 'JWT']);
    $payload = $b64(['sub' => 2, 'role' => 'customer', 'exp' => 1795000000]);
    $token = "$header.$payload.".$sign("$header.$payload");
    $this->line("الرمز: $token");

    // أي أحد يقرأ الحمولة: إنها مرمّزة لا مشفّرة
    $read = fn (string $part) => base64_decode(strtr($part, '-_', '+/'));
    $this->line('الحمولة، مقروءة بلا المفتاح: '.$read(explode('.', $token)[1]));

    $valid = function (string $jwt) use ($sign) {
        [$h, $p, $signature] = explode('.', $jwt);

        return hash_equals($sign("$h.$p"), $signature);
    };
    $this->line('التوقيع صالح: '.json_encode($valid($token)));
    // غيّر الحمولة، وأبقِ التوقيع
    $forged = $b64(['sub' => 2, 'role' => 'admin', 'exp' => 1795000000]);
    $signature = explode('.', $token)[2];
    $this->line('الرمز المعدّل صالح: '.json_encode($valid("$header.$forged.$signature")));
});
