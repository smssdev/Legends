<?php

namespace App\Console\Commands;

use App\League\LeagueFactory;
use App\League\LeagueStarter;
use App\League\MatchOrders;
use App\League\MatchRunner;
use App\Models\League;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Console\Command;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\Process\Process;

/**
 * Can this machine play 50 live matches at once [Sprint 19 B4]? It makes development leagues of 20 clubs, a
 * coach in each club, so every match of their first round is live (10 per league); runs the runner here while
 * a few other processes give orders as the coaches would; then reports how late the minutes were made and how
 * often SQLite said it was busy, and deletes everything it made (--keep to keep it).
 *   php artisan matches:load-test            (50 matches, about 6 minutes)
 */
class MatchesLoadTest extends Command
{
    protected $signature = 'matches:load-test {--matches=50} {--workers=4 : Processes giving orders} {--keep}
        {--orders-for= : (internal) a worker: the leagues whose coaches give orders} {--seconds=0 : (internal)}';

    protected $description = 'Play many live matches at once and report the delays';

    private string $token = '';

    public function handle(): int
    {
        if ($this->option('orders-for')) {
            return $this->worker(array_map('intval', explode(',', $this->option('orders-for'))), (int) $this->option('seconds'));
        }
        $token = Str::random(16);
        if (! MatchRunner::claim($token)) {
            $this->error('The match runner is on: stop it first (the "Legends Matches" task), then run this.');

            return self::FAILURE;
        }
        if (app()->isProduction() && ! $this->confirm('This adds leagues and users for a few minutes. Go on?')) {
            MatchRunner::release($token);

            return self::FAILURE;
        }
        $this->token = $token;

        $run = Str::lower(Str::random(6));
        $leagues = $this->leagues($run, (int) ceil((int) $this->option('matches') / 10));
        $ids = $leagues->pluck('id')->all();
        $this->info('Leagues '.implode(', ', $ids).' made; kick-off in about a minute.');

        $workers = collect(array_fill(0, max(0, (int) $this->option('workers')), null))->map(function () use ($ids) {
            $p = new Process([PHP_BINARY, 'artisan', 'matches:load-test', '--orders-for='.implode(',', $ids), '--seconds=600'], base_path());
            $p->setTimeout(700);
            $p->start();

            return $p;
        });

        $stats = ['steps' => 0, 'minutes' => 0, 'late' => [], 'step_ms' => [], 'busy' => 0, 'errors' => []];
        try {
            $this->play($ids, $stats);
        } finally {
            $orders = ['given' => 0, 'busy' => 0];
            foreach ($workers as $p) {
                $p->stop(1);
                $last = json_decode((string) collect(explode("\n", trim($p->getOutput())))->last(), true) ?: [];
                $orders['given'] += $last['given'] ?? 0;
                $orders['busy'] += $last['busy'] ?? 0;
            }
            $this->report($stats, $orders, $ids);
            if (! $this->option('keep')) {
                League::whereIn('id', $ids)->get()->each->delete();
                User::where('email', 'like', "load-{$run}-%")->delete();
            }
            MatchRunner::release($token);
        }

        return $stats['busy'] + $orders['busy'] === 0 && max([0, ...$stats['late']]) < 1000 ? self::SUCCESS : self::FAILURE;
    }

    /** Leagues of 20 clubs, each club with its own coach, starting now. */
    private function leagues(string $run, int $count)
    {
        $template = DB::table('master_clubs')->where('source', '!=', 'nation')->select('league_name')->groupBy('league_name')->havingRaw('count(*) >= 20')->value('league_name');
        abort_unless($template, 1, 'No template with 20 clubs.');

        return collect(range(1, $count))->map(function ($n) use ($run, $template) {
            $users = collect(range(1, 20))->map(fn ($i) => User::create(['name' => "Load {$n}-{$i}", 'email' => "load-{$run}-{$n}-{$i}@legends.invalid",
                'password' => Str::random(32), 'email_verified_at' => GameClock::now()]));
            $league = LeagueFactory::create($users[0], [
                'name' => "Load test {$run} {$n}", 'template' => $template, 'team_count' => 20, 'rounds_per_day' => 1, 'round_times' => ['21:00'],
                'prep_days' => 1, 'season_end_mode' => 'renew', 'starts_at' => GameClock::now(), 'starting_budget' => 3_000_000,
                'fair_league' => false, 'is_dev' => true,
                'master_club_id' => DB::table('master_clubs')->where('league_name', $template)->value('id'),
            ]);
            $free = DB::table('clubs')->where('league_id', $league->id)->whereNull('user_id')->pluck('id');
            foreach ($free as $i => $club) {
                DB::table('clubs')->where('id', $club)->update(['user_id' => $users[$i + 1]->id]);
            }
            LeagueStarter::start($league);
            // Only the first round: a development league starts one every minute, and a match lasts about five.
            $season = DB::table('seasons')->where('league_id', $league->id)->value('id');
            DB::table('fixtures')->where('season_id', $season)->where(fn ($q) => $q->where('round', '>', 1)->orWhere('competition', '!=', 'league'))
                ->update(['scheduled_at' => GameClock::now()->addDays(30)]);

            return $league;
        });
    }

    /** The runner, as matches:run, until the first round of every league is over. */
    private function play(array $leagues, array &$stats): void
    {
        $fixtures = fn () => DB::table('fixtures')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->whereIn('seasons.league_id', $leagues)
            ->where('fixtures.competition', 'league')->where('fixtures.round', 1)->where('fixtures.is_bye', false);
        $total = $fixtures()->count();
        $bar = $this->output->createProgressBar($total);
        while ($fixtures()->where('fixtures.status', 'finished')->count() < $total) {
            MatchRunner::claim($this->token);
            $due = DB::table('matches')->whereIn('fixture_id', $fixtures()->pluck('fixtures.id'))->where('status', 'live')->pluck('next_at', 'id');
            $at = GameClock::nowMs();
            $failed = MatchRunner::$failures;
            [, $minutes] = MatchRunner::step();
            $stats['minutes'] += $minutes;
            $new = min(MatchRunner::$failures - $failed, count(MatchRunner::$lastErrors));
            foreach ($new > 0 ? array_slice(MatchRunner::$lastErrors, -$new) : [] as $e) {
                str_contains($e, 'locked') || str_contains($e, 'busy') ? $stats['busy']++ : $stats['errors'][] = $e;
            }
            $stats['step_ms'][] = GameClock::nowMs() - $at;
            $stats['steps']++;
            // A minute made after it should have started is late.
            foreach (DB::table('matches')->whereIn('id', $due->keys())->pluck('next_at', 'id') as $id => $next) {
                if ($next !== $due[$id] && $due[$id] !== null) {
                    $stats['late'][] = max(0, $at - (int) $due[$id]);
                }
            }
            $bar->setProgress($fixtures()->where('fixtures.status', 'finished')->count());
            usleep((int) config('game.matches.runner_sleep_ms') * 1000);
        }
        $bar->finish();
        $this->newLine();
    }

    private function report(array $s, array $orders, array $leagues): void
    {
        $live = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')
            ->whereIn('seasons.league_id', $leagues)->where('matches.mode', 'live')->count();
        sort($s['late']);
        sort($s['step_ms']);
        $pct = fn (array $a, float $p) => $a ? $a[(int) floor((count($a) - 1) * $p)] : 0;
        $this->table(['', ''], [
            ['Live matches at once', $live],
            ['Minutes played', $s['minutes']],
            ['Minute made late (ms): p50 / p95 / max', $pct($s['late'], .5).' / '.$pct($s['late'], .95).' / '.($s['late'] ? end($s['late']) : 0)],
            ['Runner step (ms): p50 / p95 / max', $pct($s['step_ms'], .5).' / '.$pct($s['step_ms'], .95).' / '.($s['step_ms'] ? end($s['step_ms']) : 0)],
            ['Orders given by the coaches', $orders['given']],
            ['SQLITE_BUSY (runner / orders)', $s['busy'].' / '.$orders['busy']],
            ['Other errors', count($s['errors'])],
        ]);
        foreach (array_unique($s['errors']) as $e) {
            $this->error($e);
        }
    }

    /** A worker: coaches giving orders every few hundred ms, as from their screens. Prints its counts as JSON. */
    private function worker(array $leagues, int $seconds): int
    {
        $end = GameClock::nowMs() + $seconds * 1000;
        $given = 0;
        $busy = 0;
        while (GameClock::nowMs() < $end) {
            $m = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')
                ->whereIn('seasons.league_id', $leagues)->where('matches.status', 'live')->where('matches.mode', 'live')
                ->inRandomOrder()->select('matches.id', 'matches.tick')->first();
            if ($m) {
                try {
                    $side = random_int(0, 1) ? 'home' : 'away';
                    MatchOrders::watching($m->id, $side);
                    DB::transaction(fn () => MatchOrders::give($m->id, $side, null, Str::random(20),
                        ['type' => 'tactics', 'tactics' => ['style' => random_int(20, 80), 'tempo' => random_int(20, 80)]], $m->tick + 1));
                    $given++;
                } catch (QueryException $e) {
                    $busy += str_contains($e->getMessage(), 'locked') || str_contains($e->getMessage(), 'busy') ? 1 : 0;
                }
            }
            $this->line(json_encode(compact('given', 'busy')));
            usleep(random_int(150, 400) * 1000);
        }

        return self::SUCCESS;
    }
}
