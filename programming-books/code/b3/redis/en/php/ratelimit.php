<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

const LIMIT = 5;
const WINDOW = 10; // seconds

// one counter per client; the first request starts a 10-second window
function allow(Predis\Client $redis, string $client): array
{
    $key = "rate:$client";
    // MULTI/EXEC: both commands run together, nothing in between
    [$count] = $redis->transaction(function ($tx) use ($key) {
        $tx->incr($key);
        $tx->expire($key, WINDOW, 'NX');
    });

    return [$count <= LIMIT, $count, $key];
}

// two servers, two connections, one Redis: the limit is shared
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
        ? "allowed ($count of ".LIMIT.')'
        : 'refused, 429, try again in '.$redis->ttl($key).' s';
    echo "request $i via server $name: $answer\n";
}
