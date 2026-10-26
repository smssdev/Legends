<?php

namespace Tests\Feature;

use App\Database\Copier;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use RuntimeException;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/**
 * The game from one database into another [X43]: the league from Render's SQLite into Supabase, and Supabase into a
 * backup file and back. Whole, in its foreign keys' order, counted, and never over a game that is there.
 */
class CopierTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private const FILES = ['legacy' => 'testing-legacy.sqlite', 'moved' => 'testing-moved.sqlite'];

    protected function setUp(): void
    {
        parent::setUp();
        foreach (self::FILES as $name => $file) {
            @unlink(database_path($file));
            touch(database_path($file));
            config(["database.connections.$name" => ['driver' => 'sqlite', 'database' => database_path($file), 'prefix' => '', 'foreign_key_constraints' => true]]);
            Artisan::call('migrate', ['--database' => $name, '--force' => true]);
        }
        config(['database.default' => $this->default = config('database.default')]);
    }

    private string $default;

    protected function tearDown(): void
    {
        foreach (self::FILES as $name => $file) {
            DB::purge($name);
            @unlink(database_path($file));
        }
        parent::tearDown();
    }

    public function test_a_game_goes_whole_into_an_empty_database_and_never_over_one(): void
    {
        $this->template(full: true);
        $owner = User::factory()->create();
        $this->makeLeague($owner, ['team_count' => 4]);
        $picture = random_bytes(300)."\xff\xd8";
        DB::table('user_avatars')->insert(['user_id' => $owner->id, 'image' => $picture, 'updated_at' => GameClock::now()]);
        DB::table('players')->limit(3)->update(['in_pool' => true]);
        $file = storage_path('app/testing-copier.jsonl.gz');

        // The game into a backup file, then the file into an empty database (SQLite, as Render's league was).
        $dumped = Copier::dump($this->default, $file);
        $loaded = Copier::load($file, 'legacy');
        $sorted = function (array $a) {
            $a = array_filter($a);
            ksort($a);

            return $a;
        };
        $this->assertSame($sorted($dumped), $sorted($loaded));
        $this->assertGreaterThan(50, $loaded['players']);
        $this->assertSame($picture, DB::connection('legacy')->table('user_avatars')->value('image'));
        $this->assertSame(DB::table('players')->where('in_pool', true)->count(), DB::connection('legacy')->table('players')->where('in_pool', 1)->count());

        // Database to database, as the move to Supabase does: the same rows, ids and money.
        $moved = Copier::copy('legacy', 'moved');
        $this->assertSame($sorted($loaded), $sorted($moved));
        $this->assertSame(DB::table('clubs')->orderBy('id')->pluck('balance', 'id')->all(), DB::connection('moved')->table('clubs')->orderBy('id')->pluck('balance', 'id')->all());
        // A new row after the copy gets an id of its own.
        $next = DB::connection('moved')->table('users')->insertGetId(['name' => 'جديد', 'email' => 'new@example.com', 'password' => 'x', 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        $this->assertGreaterThan(DB::table('users')->max('id'), $next);

        // A database that holds a game is never written over.
        $this->expectException(RuntimeException::class);
        Copier::load($file, 'moved');
    }

    public function test_the_tables_come_parents_first(): void
    {
        $order = array_flip(Copier::tables($this->default));
        foreach ([['leagues', 'clubs'], ['clubs', 'players'], ['users', 'user_avatars'], ['matches', 'match_events']] as [$parent, $child]) {
            $this->assertLessThan($order[$child], $order[$parent], "$parent before $child");
        }
        $this->assertArrayNotHasKey('migrations', $order);
    }
}
