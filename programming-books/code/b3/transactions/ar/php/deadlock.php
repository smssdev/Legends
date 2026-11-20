<?php

declare(strict_types=1);

// A تقفل المنتج 1 ثم 2، وB تقفل 2 ثم 1
function run(string $name, int $first, int $second): void
{
    $db = new PDO('pgsql:host=localhost;dbname=shop', 'bit', 'secret',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $take = $db->prepare('UPDATE products SET stock = stock + 1 WHERE id = ?');
    try {
        $db->exec('BEGIN');
        $take->execute([$first]);
        usleep(200_000);
        $take->execute([$second]);
        $db->exec('COMMIT');
        echo "$name: انتهت\n";
    } catch (PDOException $e) {
        $db->exec('ROLLBACK');
        $message = preg_replace('/^ERROR:\s+/', '', strtok($e->errorInfo[2], "\n"));
        echo "$name: فشلت, {$e->getCode()}, $message\n"; // echo واحدة: عمليتان تطبعان معاً
    }
}

$pid = pcntl_fork();
if ($pid === 0) {
    // "ordered": كلتاهما تقفل الرقم الأصغر أولاً (جواب التمرين 3)
    ($argv[1] ?? '') === 'ordered' ? run('B', 1, 2) : run('B', 2, 1);
    exit(0);
}
run('A', 1, 2);
pcntl_waitpid($pid, $status);
