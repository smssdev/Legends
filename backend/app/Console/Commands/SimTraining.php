<?php

namespace App\Console\Commands;

use App\Training\Gain;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * A season of training [PLAN 2.8, Sprint 27 B2]: every player of a real league with room to grow trained without a
 * break (put back in his slot the moment it empties) for a season's sessions. The average gain must land in
 * game.training.season_gain_target (+3 to +5).
 */
class SimTraining extends Command
{
    protected $signature = 'sim:training {--league=Premier League} {--sessions= : Sessions in the season (default from config)} {--seed=1}';

    protected $description = 'A season of training on a real league, against the gain target';

    public function handle(): int
    {
        $cfg = config('game.training');
        $sessions = (int) ($this->option('sessions') ?: $cfg['season_sessions']);
        $version = DB::table('master_players')->max('data_version');
        $players = DB::table('master_players')->join('master_clubs', 'master_clubs.id', '=', 'master_players.master_club_id')
            ->where('master_clubs.league_name', $this->option('league'))->where('master_players.data_version', $version)
            ->whereColumn('master_players.potential', '>', 'master_players.overall')
            ->orderBy('master_players.id')->get(['master_players.id', 'master_players.overall', 'master_players.potential']);
        if ($players->isEmpty()) {
            $this->error('No players with room to grow in '.$this->option('league').'.');

            return self::FAILURE;
        }
        $gain = Gain::fromConfig();
        $seed = (int) $this->option('seed');
        $rows = [];
        $total = 0;
        $capped = 0;
        foreach ($players as $p) {
            $g = $gain->run((int) $p->overall, (int) $p->potential, $sessions, "{$seed}:{$p->id}");
            $total += $g;
            $capped += $p->overall + $g >= $p->potential ? 1 : 0;
            $band = intdiv($p->overall, 5) * 5;
            $rows[$band][] = $g;
        }
        ksort($rows);
        $this->table(['القوة', 'لاعبون', 'متوسط الزيادة', 'جلسات +1'], array_map(fn ($band, $g) => [
            "{$band}-".($band + 4), count($g), number_format(array_sum($g) / count($g), 2), $gain->sessions($band + 2),
        ], array_keys($rows), $rows));
        $mean = $total / $players->count();
        [$lo, $hi] = $cfg['season_gain_target'];
        $ok = $mean >= $lo && $mean <= $hi;
        $this->line(sprintf('%d لاعباً في %d جلسة: متوسط الزيادة %.2f (الهدف %d إلى %d)، ووصل %d منهم إلى أقصى إمكانيته. %s',
            $players->count(), $sessions, $mean, $lo, $hi, $capped, $ok ? 'ضمن الهدف' : 'خارج الهدف'));

        return $ok ? self::SUCCESS : self::FAILURE;
    }
}
