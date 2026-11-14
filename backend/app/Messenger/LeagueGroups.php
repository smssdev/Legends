<?php

namespace App\Messenger;

use App\Jobs\SendMessenger;
use App\League\Standings;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 67] A league's Telegram group: its owner adds the game's bot to the group and sends «/league CODE» there,
 * and each round's results and the top of the table are posted in it when the round's last match ends. Only what every
 * member already sees (results and the table), never a tactic.
 */
class LeagueGroups
{
    /** The owner links his league to this group (one group a league, one league a group). */
    public static function link(int $userId, string $code, string $chatId): ?object
    {
        $league = DB::table('leagues')->where('code', strtoupper($code))->where('owner_id', $userId)->first(['id', 'name']);
        if (! $league) {
            return null;
        }
        $season = DB::table('seasons')->where('league_id', $league->id)->orderByDesc('id')->first(['id', 'rounds_played']);
        DB::transaction(function () use ($league, $chatId, $userId, $season) {
            DB::table('messenger_groups')->where('league_id', $league->id)->orWhere('chat_id', $chatId)->delete();
            DB::table('messenger_groups')->insert(['league_id' => $league->id, 'chat_id' => $chatId, 'linked_by' => $userId,
                'season_posted' => $season?->id, 'round_posted' => (int) ($season->rounds_played ?? 0), 'linked_at' => GameClock::now()]);
        });

        return $league;
    }

    /** The owner (or whoever linked it) takes the group off. */
    public static function unlink(int $userId, string $chatId): bool
    {
        $g = DB::table('messenger_groups')->where('chat_id', $chatId)->first();
        if (! $g || ((int) $g->linked_by !== $userId && (int) DB::table('leagues')->where('id', $g->league_id)->value('owner_id') !== $userId)) {
            return false;
        }

        return DB::table('messenger_groups')->where('id', $g->id)->delete() === 1;
    }

    public static function leagueOf(string $chatId): ?int
    {
        $id = DB::table('messenger_groups')->where('chat_id', $chatId)->value('league_id');

        return $id ? (int) $id : null;
    }

    /** Called when a league's rounds played move on: the new round's results, once (a conditional update takes it). */
    public static function roundDone(int $seasonId): void
    {
        $season = DB::table('seasons')->where('id', $seasonId)->first(['id', 'league_id', 'rounds_played']);
        $g = $season ? DB::table('messenger_groups')->where('league_id', $season->league_id)->first() : null;
        $round = (int) ($season->rounds_played ?? 0);
        if (! $g || ! Telegram::configured() || $round < 1 || ((int) $g->season_posted === (int) $seasonId && (int) $g->round_posted >= $round)) {
            return;
        }
        $took = DB::table('messenger_groups')->where('id', $g->id)->where('round_posted', $g->round_posted)
            ->where(fn ($q) => $g->season_posted === null ? $q->whereNull('season_posted') : $q->where('season_posted', $g->season_posted))
            ->update(['season_posted' => $seasonId, 'round_posted' => $round]);
        if ($took !== 1) {
            return;
        }
        SendMessenger::dispatch('telegram', $g->chat_id, self::roundText($seasonId, $round))->afterCommit();
    }

    public static function roundText(int $seasonId, int $round): string
    {
        $league = DB::table('leagues')->join('seasons', 'seasons.league_id', '=', 'leagues.id')->where('seasons.id', $seasonId)
            ->first(['leagues.id', 'leagues.name', 'leagues.owner_id']);
        $en = DB::table('users')->where('id', $league->owner_id)->value('locale') === 'en';
        $fixtures = DB::table('fixtures')->where('season_id', $seasonId)->where('competition', 'league')->where('round', $round)
            ->where('is_bye', false)->where('status', 'finished')->orderBy('id')->get();
        $names = DB::table('clubs')->where('league_id', $league->id)->pluck('name', 'id');
        $lines = [$en ? "{$league->name}: round {$round}" : "{$league->name}: الجولة {$round}", ''];
        foreach ($fixtures as $f) {
            $lines[] = "{$names[$f->home_id]} {$f->home_goals} - {$f->away_goals} {$names[$f->away_id]}";
        }

        return implode("\n", [...$lines, '', self::tableText($seasonId, $en, 5)]);
    }

    /** The table's top (all of it when $top is null): place, club, points. */
    public static function tableText(int $seasonId, bool $en, ?int $top = null): string
    {
        $league = (int) DB::table('seasons')->where('id', $seasonId)->value('league_id');
        $names = DB::table('clubs')->where('league_id', $league)->pluck('name', 'id');
        $rows = Standings::table($seasonId);
        $out = [$en ? 'The table:' : 'الترتيب:'];
        foreach (array_slice($rows, 0, $top ?? count($rows)) as $i => $r) {
            $out[] = sprintf('%d. %s: %d %s (%d)', $i + 1, $names[$r['id']] ?? '?', $r['pts'], $en ? 'pts' : 'نقطة', $r['p']);
        }

        return implode("\n", $out);
    }
}
