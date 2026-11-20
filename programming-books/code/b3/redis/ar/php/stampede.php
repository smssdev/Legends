<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

$mode = $argv[1] ?? 'naive';
$connect = fn () => new Predis\Client('tcp://localhost:6379');

function productFromDb(Predis\Client $redis, int $id): array
{
    // عُدّ استعلامات قاعدة البيانات في Redis، فتضيف كل عملية إلى رقم واحد
    $redis->incr('stats:db-queries');
    $db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret');
    $query = $db->prepare('SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = ?');
    $query->execute([$id]);

    return $query->fetch(PDO::FETCH_ASSOC);
}

// احذف القفل فقط إن كان ما زال لنا، في خطوة واحدة على الخادم
const RELEASE = <<<'LUA'
    if redis.call("GET", KEYS[1]) == ARGV[1]
      then return redis.call("DEL", KEYS[1]) else return 0 end
    LUA;

function product(Predis\Client $redis, string $mode, int $id): array
{
    $key = "product:$id";
    while (true) {
        $cached = $redis->get($key);
        if ($cached !== null) {
            return json_decode($cached, true);
        }
        if ($mode === 'naive') {
            break;
        }
        // الطلب الذي يأخذ القفل وحده يسأل قاعدة البيانات؛ والباقون ينتظرون ثم يبحثون مرة أخرى
        $token = bin2hex(random_bytes(16)); // رمز عشوائي: صاحب القفل وحده يحرره
        if ($redis->set("lock:$key", $token, 'PX', 5000, 'NX')) {
            try {
                $fresh = productFromDb($redis, $id);
                $redis->set($key, json_encode($fresh), 'EX', 60);

                return $fresh;
            } finally {
                $redis->eval(RELEASE, 1, "lock:$key", $token);
            }
        }
        usleep(50_000);
    }
    $fresh = productFromDb($redis, $id);
    $redis->set($key, json_encode($fresh), 'EX', 60);

    return $fresh;
}

$connect()->del(['product:1', 'stats:db-queries']);
$start = hrtime(true);
// عشرون عملية، لكل منها اتصالاتها، كعشرين عامل PHP
$children = [];
foreach (range(1, 20) as $request) {
    $pid = pcntl_fork();
    if ($pid === 0) {
        product($connect(), $mode, 1);
        exit(0);
    }
    $children[] = $pid;
}
foreach ($children as $pid) {
    pcntl_waitpid($pid, $status);
}
$ms = round((hrtime(true) - $start) / 1e6);
$queries = $connect()->get('stats:db-queries');
printf("%-7s 20 طلباً, استعلامات قاعدة البيانات: %d, %d ms\n", $mode, $queries, $ms);
