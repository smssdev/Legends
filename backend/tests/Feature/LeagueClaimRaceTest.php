<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Symfony\Component\Process\Process;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/**
 * Sprint 13's definition of done: 20 coaches take the same club at the same moment, each in its
 * own process on the real SQLite file (not in memory, not one connection), and exactly one wins.
 */
class LeagueClaimRaceTest extends TestCase
{
    use MakesLeagues;

    private const CONNECTIONS = ['sqlite' => 'testing-race.sqlite', 'cache_db' => 'testing-race-cache.sqlite', 'queue_db' => 'testing-race-queue.sqlite'];

    private array $shared = [];

    /** Database files of its own: other processes must see committed rows, and the shared test files stay as they were. */
    protected function setUp(): void
    {
        parent::setUp();
        foreach (self::CONNECTIONS as $name => $file) {
            $this->shared[$name] = config("database.connections.{$name}.database");
            $this->removeFile($file);
            touch(database_path($file));
            config(["database.connections.{$name}.database" => database_path($file)]);
            DB::purge($name);
        }
        $this->artisan('migrate', ['--force' => true])->assertSuccessful();
    }

    protected function tearDown(): void
    {
        foreach (self::CONNECTIONS as $name => $file) {
            DB::purge($name);
            config(["database.connections.{$name}.database" => $this->shared[$name]]);
            $this->removeFile($file);
        }
        parent::tearDown();
    }

    private function removeFile(string $file): void
    {
        foreach (['', '-wal', '-shm'] as $suffix) {
            @unlink(database_path($file.$suffix));
        }
    }

    private function env(): array
    {
        return [
            'APP_ENV' => 'testing', 'DB_CONNECTION' => 'sqlite',
            'DB_DATABASE' => database_path(self::CONNECTIONS['sqlite']),
            'DB_CACHE_DATABASE' => database_path(self::CONNECTIONS['cache_db']),
            'DB_QUEUE_DATABASE' => database_path(self::CONNECTIONS['queue_db']),
            'CACHE_STORE' => 'array', 'SESSION_DRIVER' => 'array', 'BROADCAST_CONNECTION' => 'null',
        ];
    }

    /**
     * Sprint 23's definition of done: a payment tapped ten times at the same moment (ten processes, one key) is
     * paid once, and spends racing for the last money never take the club below zero.
     */
    public function test_a_payment_tapped_at_once_is_paid_once_and_racing_spends_never_overdraw(): void
    {
        $this->template();
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'starting_budget' => 1_000_000]);
        $club = $league['my_club_id'];
        $run = function (array $taps) use ($club) {
            $startAt = sprintf('%.4F', microtime(true) + 3);
            $processes = collect($taps)->map(function ($tap) use ($club, $startAt) {
                $p = new Process([PHP_BINARY, base_path('tests/Fixtures/ledger-tap.php'), $club, $tap[0], $tap[1], $startAt], base_path(), $this->env(), null, 60);
                $p->start();

                return $p;
            });

            return $processes->map(function (Process $p) {
                $p->wait();

                return trim($p->getOutput()).trim($p->getErrorOutput());
            })->all();
        };

        // Ten taps, one key: every process gets the same balance, and one row.
        $results = $run(array_fill(0, 10, ['tap:same', -300_000]));
        $this->assertSame(['700000'], array_values(array_unique($results)), implode(' | ', $results));
        $this->assertSame(1, DB::table('club_transactions')->where('idempotency_key', 'tap:same')->count());

        // Eight different spends of 300,000 for the 700,000 left: two pass, the rest are refused.
        $results = collect($run(array_map(fn ($i) => ["tap:{$i}", -300_000], range(1, 8))))->countBy()->all();
        $this->assertSame(6, $results['refused'] ?? 0, json_encode($results));
        $this->assertSame(100_000, (int) DB::table('clubs')->where('id', $club)->value('balance'));
        $this->assertSame(100_000, ClubLedger::sum($club));
    }

    public function test_twenty_coaches_reach_for_the_same_club_and_exactly_one_gets_it(): void
    {
        $this->template();
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 20, 'starting_budget' => 1_000_000]);
        $club = $this->botClub($league['id']);
        // The bot made money since: the winner's handover trims it, once.
        ClubLedger::post($club, 'opening', 700_000, 'test:bot-income');
        $coaches = collect(range(1, 20))->map(fn () => $this->approvedCoach($owner, $league));
        $this->assertSame(20, DB::table('league_join_requests')->where('status', 'approved')->count());

        $env = [
            'APP_ENV' => 'testing', 'DB_CONNECTION' => 'sqlite',
            'DB_DATABASE' => database_path(self::CONNECTIONS['sqlite']),
            'DB_CACHE_DATABASE' => database_path(self::CONNECTIONS['cache_db']),
            'DB_QUEUE_DATABASE' => database_path(self::CONNECTIONS['queue_db']),
            'CACHE_STORE' => 'array', 'SESSION_DRIVER' => 'array', 'BROADCAST_CONNECTION' => 'null',
        ];
        $startAt = sprintf('%.4F', microtime(true) + 3);
        $processes = $coaches->map(function (User $coach) use ($league, $club, $startAt, $env) {
            $p = new Process([PHP_BINARY, base_path('tests/Fixtures/league-claim.php'), $coach->id, $league['id'], $club, $startAt], base_path(), $env, null, 60);
            $p->start();

            return $p;
        });
        $results = $processes->map(function (Process $p) {
            $p->wait();

            return trim($p->getOutput()).trim($p->getErrorOutput());
        })->countBy()->all();

        $this->assertSame(['taken' => 19, 'won' => 1], collect($results)->sortKeys()->all());
        $winner = (int) DB::table('clubs')->where('id', $club)->value('user_id');
        $this->assertContains($winner, $coaches->pluck('id')->all());
        $this->assertSame(1, DB::table('league_memberships')->where('club_id', $club)->count());
        $this->assertSame(1, DB::table('club_transactions')->where('club_id', $club)->where('type', 'handover_trim')->count());
        $this->assertSame(1_000_000, (int) DB::table('clubs')->where('id', $club)->value('balance'));
        $this->assertSame(1_000_000, ClubLedger::sum($club));
    }
}
