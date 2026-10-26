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
 * On PostgreSQL (Supabase, X43) the same races run in a schema of their own, committed, each process its own connection.
 */
class LeagueClaimRaceTest extends TestCase
{
    use MakesLeagues;

    private const CONNECTIONS = ['sqlite' => 'testing-race.sqlite', 'cache_db' => 'testing-race-cache.sqlite', 'queue_db' => 'testing-race-queue.sqlite'];

    private array $shared = [];

    private function pg(): bool
    {
        return config('database.default') === 'pgsql';
    }

    /** Database files of its own: other processes must see committed rows, and the shared test files stay as they were. */
    protected function setUp(): void
    {
        parent::setUp();
        if ($this->pg()) {
            DB::statement('drop schema if exists race cascade');
            DB::statement('create schema race');
            config(['database.connections.pgsql.search_path' => 'race']);
            DB::purge('pgsql');
            $this->artisan('migrate', ['--force' => true])->assertSuccessful();

            return;
        }
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
        if ($this->pg()) {
            config(['database.connections.pgsql.search_path' => 'public']);
            DB::purge('pgsql');
            DB::statement('drop schema if exists race cascade');
            parent::tearDown();

            return;
        }
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
        if ($this->pg()) {
            return ['APP_ENV' => 'testing', 'DB_CONNECTION' => 'pgsql', 'DB_URL' => (string) env('DB_URL'), 'DB_SEARCH_PATH' => 'race',
                'DB_QUEUE_CONNECTION' => 'pgsql', 'CACHE_STORE' => 'array', 'SESSION_DRIVER' => 'array', 'BROADCAST_CONNECTION' => 'null'];
        }

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

    /** Sprint 24's definition of done: coaches buying the same pool player at the same moment; one gets him, the rest pay nothing. */
    public function test_coaches_buying_the_same_player_at_once_one_gets_him(): void
    {
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 6]);
        $clubs = [$league['my_club_id']];
        foreach (range(1, 5) as $i) {
            $coach = $this->approvedCoach($owner, $league);
            $club = $this->botClub($league['id']);
            $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertCreated();
            $clubs[] = $club;
        }
        $player = DB::table('players')->where('league_id', $league['id'])->where('in_pool', true)->orderBy('value')->value('id');
        $before = DB::table('clubs')->whereIn('id', $clubs)->pluck('balance', 'id');
        $startAt = sprintf('%.4F', microtime(true) + 3);
        $processes = collect($clubs)->map(function (int $club) use ($player, $startAt) {
            $p = new Process([PHP_BINARY, base_path('tests/Fixtures/market-buy.php'), $club, $player, $startAt], base_path(), $this->env(), null, 60);
            $p->start();

            return $p;
        });
        $results = $processes->map(function (Process $p) {
            $p->wait();

            return trim($p->getOutput()).trim($p->getErrorOutput());
        })->countBy()->all();

        $this->assertSame(['taken' => 5, 'won' => 1], collect($results)->sortKeys()->all(), json_encode($results, JSON_UNESCAPED_UNICODE));
        $owner = (int) DB::table('players')->where('id', $player)->value('club_id');
        $this->assertContains($owner, $clubs);
        foreach ($clubs as $club) {
            $paid = (int) $before[$club] - (int) DB::table('clubs')->where('id', $club)->value('balance');
            $this->assertSame($club === $owner ? (int) DB::table('players')->where('id', $player)->value('value') : 0, $paid);
            $this->assertSame((int) DB::table('clubs')->where('id', $club)->value('balance'), ClubLedger::sum($club));
        }
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

        $env = $this->env();
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
