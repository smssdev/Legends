<?php

namespace App\Database;

use Illuminate\Database\Connectors\SQLiteConnector as BaseConnector;

/**
 * Uses ImmediatePdo so the configured transaction mode applies on PHP 8.3.
 * Bound only below PHP 8.4, where Laravel handles the mode itself.
 */
class SQLiteConnector extends BaseConnector
{
    public function connect(array $config)
    {
        $pdo = parent::connect($config);

        if ($pdo instanceof ImmediatePdo) {
            $pdo->beginMode = $config['transaction_mode'] ?? 'DEFERRED';
        }

        return $pdo;
    }

    protected function createPdoConnection($dsn, $username, #[\SensitiveParameter] $password, $options)
    {
        return new ImmediatePdo($dsn, $username, $password, $options);
    }
}
