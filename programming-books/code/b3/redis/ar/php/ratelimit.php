<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

const LIMIT = 5;
const WINDOW = 10; // seconds

// عداد لكل عميل؛ وأول طلب يبدأ نافذة من 10 ثوانٍ
function allow(Predis\Client $redis, string $client): array
{
    $key = "rate:$client";
    // MULTI/EXEC: الأمران ينفذان معاً، ولا شيء بينهما
    [$count] = $redis->transaction(function ($tx) use ($key) {
        $tx->incr($key);
        $tx->expire($key, WINDOW, 'NX');
    });

    return [$count <= LIMIT, $count, $key];
}

// خادمان، واتصالان، وRedis واحد: الحد مشترك
$servers = [
    'A' => new Predis\Client('tcp://localhost:6379'),
    'B' => new Predis\Client('tcp://localhost:6379'),
];
$servers['A']->del('rate:203.0.113.7');
foreach (range(1, 8) as $i) {
    $name = $i % 2 === 1 ? 'A' : 'B';
    $redis = $servers[$name];
    [$allowed, $count, $key] = allow($redis, '203.0.113.7');
    $answer = $allowed
        ? "مسموح ($count من ".LIMIT.')'
        : 'مرفوض، 429، حاول بعد '.$redis->ttl($key).' ث';
    echo "الطلب $i عبر الخادم $name: $answer\n";
}
