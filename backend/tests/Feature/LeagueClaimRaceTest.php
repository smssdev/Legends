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
