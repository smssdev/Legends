<?php

declare(strict_types=1);

$connect = fn () => new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$level = $argv[1] ?? 'READ COMMITTED';
$a = $connect();
$b = $connect();
$price = fn () => $a->query('SELECT price FROM products WHERE id = 1')->fetchColumn();

// A reads, B changes and commits, A reads again, then A tries to change it
$a->exec("BEGIN ISOLATION LEVEL $level");
echo 'A reads the price: ', $price(), "\n";
$b->exec('UPDATE products SET price = 50000 WHERE id = 1');
echo "B sets the price to 50000 and commits\n";
echo 'A reads it again: ', $price(), "\n";
try {
    $a->exec('UPDATE products SET price = price + 1000 WHERE id = 1');
    $a->exec('COMMIT');
    echo 'A adds 1000 to the price: ', $price(), "\n";
} catch (PDOException $e) {
    $a->exec('ROLLBACK');
    echo 'A adds 1000 to the price: ERROR ', preg_replace('/^ERROR:\s+/', '', $e->errorInfo[2]), "\n";
}
$b->exec('UPDATE products SET price = 45000 WHERE id = 1');
