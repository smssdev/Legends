<?php

declare(strict_types=1);

require __DIR__.'/vendor/autoload.php';

$db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$redis = new Predis\Client('tcp://localhost:6379');

// الاستعلام البطيء: pg_sleep تمثل تقريراً ثقيلاً أو ربطاً بين جداول كبيرة
function productFromDb(PDO $db, int $id): array
{
    $query = $db->prepare('SELECT id, name, price FROM products, pg_sleep(0.2) WHERE id = ?');
    $query->execute([$id]);

    return $query->fetch();
}

// التخزين جانباً: ابحث في Redis أولاً؛ وعند الغياب اسأل قاعدة البيانات واحفظ الجواب
function product(PDO $db, Predis\Client $redis, int $id): array
{
    $key = "product:$id";
    $cached = $redis->get($key);
    if ($cached !== null) {
        return [json_decode($cached, true), 'Redis'];
    }
    $fresh = productFromDb($db, $id);
    // يُنسى بعد 60 ثانية، حتى لو لم يحذفه أحد
    $redis->set($key, json_encode($fresh), 'EX', 60);

    return [$fresh, 'PostgreSQL'];
}

// تغيير البيانات: حدّث قاعدة البيانات أولاً، ثم احذف النسخة المخزنة
function setPrice(PDO $db, Predis\Client $redis, int $id, int $price): void
{
    $db->prepare('UPDATE products SET price = ? WHERE id = ?')->execute([$price, $id]);
    $redis->del("product:$id");
}

$timed = function (string $label, int $id) use ($db, $redis): void {
    $start = hrtime(true);
    [$product, $from] = product($db, $redis, $id);
    $ms = round((hrtime(true) - $start) / 1e6);
    printf("%s %s, %d, من %s في %d ms\n",
        mb_str_pad($label, 16), $product['name'], $product['price'], $from, $ms);
};

$redis->del('product:1');
$timed('الطلب الأول', 1);
$timed('الطلب الثاني', 1);
$timed('الطلب الثالث', 1);
setPrice($db, $redis, 1, 47000);
echo "تغير السعر إلى 47000، وحُذفت النسخة المخزنة\n";
$timed('بعد التغيير', 1);
echo 'الثواني الباقية في Redis: ', $redis->ttl('product:1'), "\n";
