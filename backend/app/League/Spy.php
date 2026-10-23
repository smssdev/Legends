<?php

namespace App\League;

use App\Economy\Economy;
use App\Models\Club;
use App\Support\GameClock;
use App\Wallet\Price;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Spying on the next opponent [docs/features/spy.md, Sprint 30]: before the lock, a paid report of what the opponent
 * has saved at that moment: the formation, the eleven and the bench, the four public tactics, the form and the
 * eleven's fitness. It is built from an allowlist, so pressing, style, tempo, positions, the defensive shape and any
 * secret training can never be in it. The opponent is not told.
 */
class Spy
{
    public static function cost(int $leagueId): int
    {
        return intdiv(Economy::scale($leagueId) * (int) config('game.spy.cost_bp'), 10000);
    }

    /** Send the spy for this fixture. Returns the report. */
    public static function send(int $clubId, object $fixture): array
    {
        return DB::transaction(function () use ($clubId, $fixture) {
            if ($fixture->status !== 'scheduled') {
                throw new HttpException(409, 'قُفلت التشكيلة: تشكيلة الخصم وتكتيكه العلني في «المباراة القادمة».');
            }
            if (DB::table('spy_reports')->where('club_id', $clubId)->where('fixture_id', $fixture->id)->exists()) {
                throw new HttpException(409, 'أرسلت جاسوساً لهذه المباراة.');
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            $target = Club::findOrFail($fixture->home_id === $clubId ? $fixture->away_id : $fixture->home_id);
            $report = self::report($target);
            $cost = self::cost($club->league_id);
            $now = GameClock::now();
            $id = DB::table('spy_reports')->insertGetId(['club_id' => $clubId, 'fixture_id' => $fixture->id, 'target_club_id' => $target->id,
                'report' => json_encode($report), 'cost' => $cost, 'created_at' => $now, 'updated_at' => $now]);
            Price::charge($clubId, 'spy', $cost, "spy:{$id}", "fixture:{$fixture->id}");

            return $report;
        });
    }

    /** What the spy sees, item by item of the spec, and nothing else. */
    public static function report(Club $target): array
    {
        $sheet = TeamSheet::current($target);
        $ids = array_values(array_filter(array_merge($sheet['starters'], $sheet['bench'])));
        $players = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->whereIn('players.id', $ids)
            ->get(['players.id', 'players.overall', 'players.training_bonus', 'players.fitness', 'master_players.name', 'master_players.position', 'master_players.line'])
            ->keyBy('id');
        $row = fn ($id) => isset($players[$id]) ? ['id' => (int) $id, 'name' => $players[$id]->name, 'position' => $players[$id]->position,
            'line' => $players[$id]->line, 'overall' => $players[$id]->overall + $players[$id]->training_bonus] : null;
        $eleven = array_values(array_filter(array_map($row, $sheet['starters'])));
        $fitness = array_map(fn ($p) => (int) $players[$p['id']]->fitness, $eleven);
        $formation = str_starts_with($sheet['formation'], 'custom:')
            ? (collect(TeamSheet::customs($target))->firstWhere('number', (int) substr($sheet['formation'], 7))['name'] ?? 'خطة خاصة')
            : $sheet['formation'];

        return [
            'club' => ['id' => $target->id, 'name' => $target->name],
            'at' => GameClock::now()->toIso8601ZuluString(),
            'formation' => $formation,
            'starters' => $eleven,
            'bench' => array_values(array_filter(array_map($row, $sheet['bench']))),
            'tactics' => Tactics::public(Tactics::of($target)),
            'form' => self::form($target->id),
            'fitness' => $fitness ? intdiv(array_sum($fitness), count($fitness)) : null,
        ];
    }

    /** The last five results in every competition, newest first: W, D or L. */
    private static function form(int $clubId): array
    {
        return DB::table('fixtures')->where('status', 'finished')->whereNotNull('home_goals')
            ->where(fn ($q) => $q->where('home_id', $clubId)->orWhere('away_id', $clubId))
            ->orderByDesc('scheduled_at')->limit(5)->get()
            ->map(function ($f) use ($clubId) {
                [$for, $against] = $f->home_id === $clubId ? [$f->home_goals, $f->away_goals] : [$f->away_goals, $f->home_goals];

                return $for > $against ? 'W' : ($for < $against ? 'L' : 'D');
            })->all();
    }
}
