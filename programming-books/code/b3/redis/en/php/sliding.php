<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

const LIMIT = 3;
const WINDOW_MS = 2000;
$redis = new Predis\Client('tcp://localhost:6379');

// exercise 5: a sliding window, one sorted-set member per request, scored by its time
function allow(Predis\Client $redis, string $client): bool
{
    $key = "sliding:$client";
    $now = (int) (microtime(true) * 1000);
    [, , $count] = $redis->transaction(function ($tx) use ($key, $now) {
        $tx->zremrangebyscore($key, 0, $now - WINDOW_MS);
        $tx->zadd($key, [$now.'-'.mt_rand() => $now]);
        $tx->zcard($key);
        $tx->pexpire($key, WINDOW_MS);
    });

    return $count <= LIMIT;
}

$redis->del('sliding:203.0.113.7');
foreach (range(1, 5) as $i) {
    if ($i === 5) {
        usleep(2_000_000);
        echo "(2 seconds later)\n";
    }
    $allowed = allow($redis, '203.0.113.7');
    echo "request $i: ", $allowed ? 'allowed' : 'refused, 429', "\n";
}
