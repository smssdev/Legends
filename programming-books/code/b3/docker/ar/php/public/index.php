<?php

declare(strict_types=1);

$db = new PDO(getenv('DATABASE_URL'), getenv('DATABASE_USER'), getenv('DATABASE_PASSWORD'),
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

header('Content-Type: application/json');
echo json_encode(match ($path) {
    '/health' => ['status' => 'ok'],
    '/products' => $db->query('SELECT * FROM products ORDER BY id')->fetchAll(),
    default => ['title' => 'Not found'],
}, JSON_UNESCAPED_UNICODE);
