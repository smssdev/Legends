<?php

declare(strict_types=1);

// A locks product 1 then 2; B locks 2 then 1
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
        echo "$name: done\n";
    } catch (PDOException $e) {
        $db->exec('ROLLBACK');
        $message = preg_replace('/^ERROR:\s+/', '', strtok($e->errorInfo[2], "\n"));
        echo "$name: failed, {$e->getCode()}, $message\n"; // one echo: two processes print at once
    }
}

$pid = pcntl_fork();
if ($pid === 0) {
    // "ordered": both lock the lower id first (the answer to exercise 3)
    ($argv[1] ?? '') === 'ordered' ? run('B', 1, 2) : run('B', 2, 1);
    exit(0);
}
run('A', 1, 2);
pcntl_waitpid($pid, $status);
