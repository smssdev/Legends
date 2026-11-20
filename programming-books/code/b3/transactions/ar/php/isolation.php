<?php

declare(strict_types=1);

$connect = fn () => new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$level = $argv[1] ?? 'READ COMMITTED';
$a = $connect();
$b = $connect();
$price = fn () => $a->query('SELECT price FROM products WHERE id = 1')->fetchColumn();

// A تقرأ، وB تغيّر وتثبّت، وA تقرأ مرة أخرى، ثم تحاول A أن تغيّر
$a->exec("BEGIN ISOLATION LEVEL $level");
echo 'A تقرأ السعر: ', $price(), "\n";
$b->exec('UPDATE products SET price = 50000 WHERE id = 1');
echo "B تضبط السعر على 50000 وتثبّت\n";
echo 'A تقرؤه مرة أخرى: ', $price(), "\n";
try {
    $a->exec('UPDATE products SET price = price + 1000 WHERE id = 1');
    $a->exec('COMMIT');
    echo 'A تضيف 1000 إلى السعر: ', $price(), "\n";
} catch (PDOException $e) {
    $a->exec('ROLLBACK');
    echo 'A تضيف 1000 إلى السعر: ERROR ', preg_replace('/^ERROR:\s+/', '', $e->errorInfo[2]), "\n";
}
$b->exec('UPDATE products SET price = 45000 WHERE id = 1');
