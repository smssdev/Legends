<?php

namespace App\Experience;

use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 64 B8] A player's milestones with his club, from the finished matches' sheets (match_stats): his tenth goal,
 * his fiftieth match, his first man of the match (game.experience.milestones). Each once (player, kind, value), with a
 * message to his coach and a small card on the office until it is seen. Counted, never stored as a running total.
 */
class PlayerMilestones
{
    public const KINDS = ['goals', 'matches', 'motm'];

    /** After a match's sheets are written: the milestones its players reached for this club. */
    public static function after(int $matchId, int $clubId, array $state): void
    {
        $steps = config('game.experience.milestones');
        $sheet = DB::table('match_stats')->where('match_id', $matchId)->where('club_id', $clubId)->value('players');
        $now = array_values(array_filter(json_decode((string) $sheet, true) ?? [], fn ($p) => $p['played'] ?? false));
        if (! $now) {
            return;
        }
        $ids = array_map(fn ($p) => (int) $p['id'], $now);
        $totals = array_fill_keys($ids, ['goals' => 0, 'matches' => 0]);
        $motm = array_fill_keys($ids, 0);
        $best = self::best($state);
        foreach (DB::table('match_stats')->where('club_id', $clubId)->get(['match_id', 'players']) as $row) {
            foreach (json_decode((string) $row->players, true) ?? [] as $p) {
                $id = (int) $p['id'];
                if (isset($totals[$id]) && ($p['played'] ?? false)) {
                    $totals[$id]['goals'] += (int) ($p['goals'] ?? 0);
                    $totals[$id]['matches']++;
                }
            }
        }
        // The man of the match: his past ones from the milestones already given, and this one.
        $before = DB::table('player_milestones')->whereIn('player_id', $ids)->where('kind', 'motm')->selectRaw('player_id, max(value) as n')
            ->groupBy('player_id')->pluck('n', 'player_id');
        if ($best !== null && isset($motm[$best])) {
            $motm[$best] = (int) ($before[$best] ?? 0) + 1;
        }
        $coach = DB::table('clubs')->where('id', $clubId)->first(['user_id', 'league_id']);
        $names = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->whereIn('players.id', $ids)->pluck('master_players.name', 'players.id');
        foreach ($ids as $id) {
            $reached = [];
            foreach (['goals' => $totals[$id]['goals'], 'matches' => $totals[$id]['matches'], 'motm' => $motm[$id]] as $kind => $n) {
                // Only a step crossed in this match (so an old total never fires late).
                $last = $kind === 'goals' ? $n - self::goalsHere($now, $id) : $n - 1;
                foreach ($steps[$kind] as $step) {
                    if ($n >= $step && $last < $step) {
                        $reached[] = [$kind, $step];
                    }
                }
            }
            foreach ($reached as [$kind, $step]) {
                $new = DB::table('player_milestones')->insertOrIgnore(['player_id' => $id, 'club_id' => $clubId, 'match_id' => $matchId,
                    'kind' => $kind, 'value' => $step, 'created_at' => GameClock::now()]);
                if ($new === 1 && $coach?->user_id) {
                    Inbox::send((int) $coach->user_id, 'player_milestone', ['player' => $names[$id] ?? '', 'kind' => $kind, 'value' => $step], (int) $coach->league_id, $clubId);
                }
            }
        }
    }

    /** The club's milestones not yet seen, newest first, for the office's card. */
    public static function unseen(int $clubId): array
    {
        return DB::table('player_milestones')->join('players', 'players.id', '=', 'player_milestones.player_id')
            ->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('player_milestones.club_id', $clubId)->whereNull('player_milestones.seen_at')
            ->orderByDesc('player_milestones.id')->limit(5)
            ->get(['player_milestones.id', 'player_milestones.player_id', 'master_players.name', 'player_milestones.kind', 'player_milestones.value'])
            ->map(fn ($m) => ['id' => (int) $m->id, 'player_id' => (int) $m->player_id, 'name' => $m->name, 'kind' => $m->kind, 'value' => (int) $m->value])->all();
    }

    public static function seen(int $clubId): int
    {
        return DB::table('player_milestones')->where('club_id', $clubId)->whereNull('seen_at')->update(['seen_at' => GameClock::now()]);
    }

    private static function goalsHere(array $sheet, int $id): int
    {
        foreach ($sheet as $p) {
            if ((int) $p['id'] === $id) {
                return (int) ($p['goals'] ?? 0);
            }
        }

        return 0;
    }

    /** The match's best rating on either side (the report's man of the match). */
    private static function best(array $state): ?int
    {
        $best = null;
        $top = -1;
        foreach (['home', 'away'] as $t) {
            foreach ($state['teams'][$t]['players'] as $p) {
                if (($p['on'] || $p['out'] !== '') && $p['st']['r'] > $top) {
                    $top = $p['st']['r'];
                    $best = (int) $p['id'];
                }
            }
        }

        return $best;
    }
}
