<?php

declare(strict_types=1);

// the length tells the client where the body ends (the built-in server does not say)
function send(mixed $data): void
{
    $body = json_encode($data);
    header('Content-Type: application/json');
    header('Content-Length: '.strlen($body));
    echo $body;
}

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if ($path === '/products') {
    $db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret');
    $query = $db->prepare('SELECT id, name, price FROM products WHERE category = ? ORDER BY price LIMIT 20');
    $query->execute([$_GET['category'] ?? '']);
    send($query->fetchAll(PDO::FETCH_ASSOC));
} elseif ($path === '/slow') {
    // a call to another service that takes 100 ms, while the process waits
    usleep(100_000);
    send(['ok' => true]);
} else {
    send(['ok' => true]);
}
