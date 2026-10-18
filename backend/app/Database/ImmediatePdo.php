<?php

namespace App\Database;

use PDO;

/**
 * Before PHP 8.4, Laravel ignores the sqlite `transaction_mode` option and
 * PDO starts every transaction as DEFERRED, so two writers can both begin and
 * one then fails with SQLITE_BUSY mid-transaction. This PDO begins with the
 * configured mode instead (IMMEDIATE takes the write lock up front).
 */
class ImmediatePdo extends PDO
{
    public string $beginMode = 'DEFERRED';

    private bool $open = false;

    public function beginTransaction(): bool
    {
        $this->exec("BEGIN {$this->beginMode} TRANSACTION");

        return $this->open = true;
    }

    public function commit(): bool
    {
        $this->exec('COMMIT');
        $this->open = false;

        return true;
    }

    public function rollBack(): bool
    {
        $this->exec('ROLLBACK');
        $this->open = false;

        return true;
    }

    public function inTransaction(): bool
    {
        return $this->open;
    }
}
