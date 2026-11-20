<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

$db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$redis = new Predis\Client('tcp://localhost:6379');

// the slow query: pg_sleep stands for a heavy report or a join over big tables
function productFromDb(PDO $db, int $id): array
{
    $query = $db->prepare('SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = ?');
    $query->execute([$id]);

    return $query->fetch();
}

// cache-aside: look in Redis first; on a miss, ask the database and keep the answer
function product(PDO $db, Predis\Client $redis, int $id): array
{
    $key = "product:$id";
    $cached = $redis->get($key);
    if ($cached !== null) {
        return [json_decode($cached, true), 'Redis'];
    }
    $fresh = productFromDb($db, $id);
    // forgotten after 60 seconds, even if nobody deletes it
    $redis->set($key, json_encode($fresh), 'EX', 60);

    return [$fresh, 'PostgreSQL'];
}

// changing the data: update the database first, then delete the cached copy
function setPrice(PDO $db, Predis\Client $redis, int $id, int $price): void
{
    $db->prepare('UPDATE products SET price = ? WHERE id = ?')->execute([$price, $id]);
    $redis->del("product:$id");
}

$timed = function (string $label, int $id) use ($db, $redis): void {
    $start = hrtime(true);
    [$product, $from] = product($db, $redis, $id);
    $ms = round((hrtime(true) - $start) / 1e6);
    printf("%s %s, %d, from %s in %d ms\n",
        mb_str_pad($label, 16), $product['name'], $product['price'], $from, $ms);
};

$redis->del('product:1');
$timed('first request', 1);
$timed('second request', 1);
$timed('third request', 1);
setPrice($db, $redis, 1, 47000);
echo "price changed to 47000, cached copy deleted\n";
$timed('after the change', 1);
echo 'seconds left in Redis: ', $redis->ttl('product:1'), "\n";
