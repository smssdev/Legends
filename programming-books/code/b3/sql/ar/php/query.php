<?php

declare(strict_types=1);

$db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, // الأخطاء تصير استثناءات، لا false صامتة
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

// ما قد يرسله نموذج على أنه بريد: يغلق علامة التنصيص ويضيف شرطاً.
$input = "x' OR '1'='1";

// خطأ: المدخل يصير جزءاً من SQL
$unsafe = $db->query("SELECT id, email FROM customers WHERE email = '$input'");
echo 'وصل النصوص: ', count($unsafe->fetchAll()), " صفوف\n";

// صحيح: SQL والقيمة يسافران منفصلين، و? قيمة دائماً لا غير
$safe = $db->prepare('SELECT id, email FROM customers WHERE email = ?');
$safe->execute([$input]);
echo 'معامل: ', count($safe->fetchAll()), " صفوف\n";

$sara = $db->prepare('SELECT c.name, count(o.id) AS orders FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.id WHERE c.email = ? GROUP BY c.name');
$sara->execute(['sara@example.com']);
var_dump($sara->fetch());
