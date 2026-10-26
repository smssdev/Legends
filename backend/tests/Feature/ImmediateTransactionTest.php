<?php

namespace Tests\Feature;

use App\Providers\AppServiceProvider;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use PDO;
use PDOException;
use Tests\TestCase;

class ImmediateTransactionTest extends TestCase
{
    public function test_a_transaction_takes_the_write_lock_as_soon_as_it_begins(): void
    {
        if (config('database.default') === 'pgsql') {
            // [X43] PostgreSQL: the game's one lock, taken as the transaction begins; another connection waits for it.
            $c = DB::connection()->getConfig();
            $other = new PDO("pgsql:host={$c['host']};port={$c['port']};dbname={$c['database']}", $c['username'], $c['password']);
            $try = fn () => $other->query('select pg_try_advisory_lock('.AppServiceProvider::WRITE_LOCK.')')->fetchColumn();
            DB::beginTransaction();
            try {
                $this->assertFalse($try());
            } finally {
                DB::rollBack();
            }
            $this->assertTrue($try());
            $other->query('select pg_advisory_unlock('.AppServiceProvider::WRITE_LOCK.')');

            return;
        }
        $file = config('database.connections.sqlite.database');
        $other = new PDO('sqlite:'.$file);
        $other->exec('pragma busy_timeout = 0');

        DB::beginTransaction();

        try {
            // With DEFERRED this would succeed: no write has happened yet.
            $other->exec('begin immediate');
            $this->fail('A second writer got the lock while our transaction was open.');
        } catch (PDOException $e) {
            $this->assertStringContainsString('locked', $e->getMessage());
        } finally {
            DB::rollBack();
        }

        $other->exec('begin immediate');
        $other->exec('rollback');
    }

    public function test_commit_rollback_and_nested_transactions_still_work(): void
    {
        Schema::dropIfExists('tx_probe');
        Schema::create('tx_probe', fn ($table) => $table->integer('n'));

        DB::transaction(function () {
            DB::table('tx_probe')->insert(['n' => 1]);

            try {
                DB::transaction(function () {
                    DB::table('tx_probe')->insert(['n' => 2]);
                    throw new \RuntimeException('undo the inner insert');
                });
            } catch (\RuntimeException) {
            }
        });

        try {
            DB::transaction(function () {
                DB::table('tx_probe')->insert(['n' => 3]);
                throw new \RuntimeException('undo the whole transaction');
            });
        } catch (\RuntimeException) {
        }

        $this->assertSame([1], DB::table('tx_probe')->pluck('n')->all());
        $this->assertSame(0, DB::transactionLevel());

        Schema::drop('tx_probe');
    }
}
