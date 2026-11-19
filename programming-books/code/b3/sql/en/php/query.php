<?php

declare(strict_types=1);

$db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, // errors become exceptions, not silent false
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

// What a form might send as an email: it closes the quote and adds a condition.
$input = "x' OR '1'='1";

// WRONG: the input becomes part of the SQL
$unsafe = $db->query("SELECT id, email FROM customers WHERE email = '$input'");
echo 'string concatenation: ', count($unsafe->fetchAll()), " rows\n";

// Right: the SQL and the value travel separately; ? is only ever a value
$safe = $db->prepare('SELECT id, email FROM customers WHERE email = ?');
$safe->execute([$input]);
echo 'parameter: ', count($safe->fetchAll()), " rows\n";

$sara = $db->prepare('SELECT c.name, count(o.id) AS orders FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.id WHERE c.email = ? GROUP BY c.name');
$sara->execute(['sara@example.com']);
var_dump($sara->fetch());
