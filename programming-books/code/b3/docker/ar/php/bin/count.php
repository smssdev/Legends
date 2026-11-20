<?php

$db = new PDO(getenv('DATABASE_URL'), getenv('DATABASE_USER'), getenv('DATABASE_PASSWORD'));
echo json_encode(['products' => (int) $db->query('SELECT count(*) FROM products')->fetchColumn()]), "\n";
