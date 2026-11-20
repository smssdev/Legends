<?php

declare(strict_types=1);

$connect = fn () => new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$mode = $argv[1] ?? 'naive';

function buy(PDO $db, string $mode, int $buyer): int
{
    $retries = 0;
    while (true) {
        try {
            $db->exec($mode === 'serializable' ? 'BEGIN ISOLATION LEVEL SERIALIZABLE' : 'BEGIN');
            if ($mode === 'atomic') {
                // جملة واحدة: تفحص قاعدة البيانات المخزون وتغيّره معاً
                $taken = $db->exec('UPDATE products SET stock = stock - 1 WHERE id = 1 AND stock > 0');
                if ($taken === 1) {
                    $db->prepare('INSERT INTO orders (product_id, buyer) VALUES (1, ?)')->execute([$buyer]);
                }
            } else {
                // اقرأ، وقرر في الكود، ثم اكتب: السباق الكلاسيكي
                // FOR UPDATE تقفل الصف: ينتظر المشترون الآخرون هنا حتى تنتهي هذه المعاملة
                $lock = $mode === 'lock' ? ' FOR UPDATE' : '';
                $stock = (int) $db->query("SELECT stock FROM products WHERE id = 1$lock")->fetchColumn();
                // الوقت الذي يمضيه تطبيق حقيقي بين القراءة والكتابة: استدعاء خدمة دفع مثلاً
                $db->query('SELECT pg_sleep(0.1)');
                if ($stock > 0) {
                    $db->prepare('UPDATE products SET stock = ? WHERE id = 1')->execute([$stock - 1]);
                    $db->prepare('INSERT INTO orders (product_id, buyer) VALUES (1, ?)')->execute([$buyer]);
                }
            }
            $db->exec('COMMIT');
            return $retries;
        } catch (PDOException $e) {
            $db->exec('ROLLBACK');
            // فشل التسلسل: ابدأ المعاملة كلها من جديد
            if ($e->getCode() !== '40001') {
                throw $e;
            }
            $retries++;
        }
    }
}

$setup = $connect();
$setup->exec('TRUNCATE orders; UPDATE products SET stock = 1 WHERE id = 1');
$setup = null; // تُغلق قبل التفرع: لا يشارك ابن اتصال أبيه أبداً

// عشر عمليات، لكل منها اتصالها، تشتري في اللحظة نفسها.
$children = [];
foreach (range(1, 10) as $buyer) {
    $pid = pcntl_fork();
    if ($pid === 0) {
        exit(buy($connect(), $mode, $buyer));
    }
    $children[] = $pid;
}
$retries = 0;
foreach ($children as $pid) {
    pcntl_waitpid($pid, $status);
    $retries += pcntl_wexitstatus($status);
}

$admin = $connect();
$sold = $admin->query('SELECT count(*) FROM orders')->fetchColumn();
$stock = $admin->query('SELECT stock FROM products WHERE id = 1')->fetchColumn();
printf("%-12s 1 في المخزون, %d مبيعات, المخزون الآن %d%s\n", $mode, $sold, $stock,
    $mode === 'serializable' ? ", $retries إعادات" : '');
