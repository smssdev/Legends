<?php

namespace App\Messenger;

use App\Jobs\SendMessenger;
use App\League\Newspaper;
use App\League\Standings;
use App\Models\League;
use App\Support\GameClock;
use Illuminate\Support\Facades\App;
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

    /** [Sprint 68] The owner (or whoever linked it) turns the group's live goals on or off. */
    public static function live(int $userId, string $chatId, bool $on): bool
    {
        $g = DB::table('messenger_groups')->where('chat_id', $chatId)->first();
        if (! $g || ((int) $g->linked_by !== $userId && (int) DB::table('leagues')->where('id', $g->league_id)->value('owner_id') !== $userId)) {
            return false;
        }

        return DB::table('messenger_groups')->where('id', $g->id)->update(['live' => $on]) >= 0;
    }

    /**
     * [Sprint 68] Before each round, a poll in each league group: who wins the round's big match (the two strongest
     * sides that meet), once a round, within game.messenger.poll_hours of its first kick-off. Sent at once (its
     * message is needed to settle it). Returns how many were posted.
     */
    public static function polls(): int
    {
        if (! Telegram::configured()) {
            return 0;
        }
        $n = 0;
        $now = GameClock::now();
        $until = $now->copy()->addHours((int) config('game.messenger.poll_hours'));
        foreach (DB::table('messenger_groups')->get() as $g) {
            $season = DB::table('seasons')->where('league_id', $g->league_id)->orderByDesc('id')->value('id');
            $round = $season ? DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('is_bye', false)
                ->where('status', 'scheduled')->min('round') : null;
            if (! $round) {
                continue;
            }
            $fixtures = DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('round', $round)
                ->where('is_bye', false)->whereNotNull('home_id')->whereNotNull('away_id')->get();
            $first = $fixtures->min('scheduled_at');
            if (! $first || $fixtures->where('status', '!=', 'scheduled')->isNotEmpty() || ! GameClock::now()->lt($first) || $until->lt($first)) {
                continue;
            }
            $strength = DB::table('clubs')->where('league_id', $g->league_id)->pluck('strength_snapshot', 'id');
            $big = $fixtures->sortByDesc(fn ($f) => (int) ($strength[$f->home_id] ?? 0) + (int) ($strength[$f->away_id] ?? 0))->first();
            if (DB::table('messenger_polls')->where('group_id', $g->id)->whereIn('fixture_id', $fixtures->pluck('id'))->exists()) {
                continue;
            }
            $names = DB::table('clubs')->whereIn('id', [$big->home_id, $big->away_id])->pluck('name', 'id');
            $en = DB::table('leagues')->join('users', 'users.id', '=', 'leagues.owner_id')->where('leagues.id', $g->league_id)->value('users.locale') === 'en';
            $message = Telegram::poll($g->chat_id, $en ? "Round {$round}: who wins {$names[$big->home_id]} - {$names[$big->away_id]}?" : "الجولة {$round}: من يفوز في {$names[$big->home_id]} - {$names[$big->away_id]}؟",
                [$names[$big->home_id], $en ? 'A draw' : 'تعادل', $names[$big->away_id]]);
            if ($message) {
                DB::table('messenger_polls')->insertOrIgnore(['group_id' => $g->id, 'fixture_id' => $big->id, 'chat_id' => $g->chat_id,
                    'message_id' => $message, 'created_at' => $now]);
                $n++;
            }
        }

        return $n;
    }

    /** [Sprint 68] The poll's match ended: the poll closes and the answer is posted under it, once. */
    public static function fixtureDone(object $f): void
    {
        foreach (DB::table('messenger_polls')->where('fixture_id', $f->id)->whereNull('settled_at')->get() as $p) {
            if (DB::table('messenger_polls')->where('id', $p->id)->whereNull('settled_at')->update(['settled_at' => GameClock::now()]) !== 1) {
                continue;
            }
            $fx = DB::table('fixtures')->where('id', $f->id)->first();
            $names = DB::table('clubs')->whereIn('id', [$fx->home_id, $fx->away_id])->pluck('name', 'id');
            $en = DB::table('messenger_groups')->join('leagues', 'leagues.id', '=', 'messenger_groups.league_id')
                ->join('users', 'users.id', '=', 'leagues.owner_id')->where('messenger_groups.id', $p->group_id)->value('users.locale') === 'en';
            $h = (int) $fx->home_goals;
            $a = (int) $fx->away_goals;
            $answer = $h === $a ? ($en ? 'a draw' : 'التعادل') : ($en ? $names[$h > $a ? $fx->home_id : $fx->away_id].' won' : 'فوز '.$names[$h > $a ? $fx->home_id : $fx->away_id]);
            SendMessenger::dispatch('telegram', $p->chat_id, ($en ? 'The answer: ' : 'الإجابة: ')."{$answer}\n{$names[$fx->home_id]} {$h} - {$a} {$names[$fx->away_id]}",
                false, [], (int) $p->message_id, (int) $p->message_id)->afterCommit();
        }
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
        // [Sprint 69] And the round's stars, from the league's newspaper.
        $stars = self::starsText((int) $season->league_id, $round);
        if ($stars !== null) {
            SendMessenger::dispatch('telegram', $g->chat_id, $stars)->afterCommit();
        }
    }

    /**
     * [Sprint 69] The round's stars as the league's newspaper names them (Newspaper::edition): its player, its coach,
     * its team (by line) and its big stories. Null before the round is fully played.
     */
    public static function starsText(int $leagueId, int $round): ?string
    {
        $league = League::find($leagueId);
        $en = DB::table('users')->where('id', $league?->owner_id)->value('locale') === 'en';
        $before = App::getLocale();
        App::setLocale($en ? 'en' : 'ar');
        try {
            $e = $league ? Newspaper::edition($league, $round) : null;
        } finally {
            App::setLocale($before);
        }
        if (! $e || (int) $e['round'] !== $round) {
            return null;
        }
        $out = [$en ? "The stars of round {$round}" : "نجوم الجولة {$round}", ''];
        if ($e['player']) {
            $p = $e['player'];
            $out[] = ($en ? 'Player of the round: ' : 'لاعب الجولة: ')."{$p['name']} ({$p['club']})".($p['goals'] ? ($en ? ", {$p['goals']} goals" : "، {$p['goals']} أهداف") : '');
        }
        if ($e['coach']) {
            $c = $e['coach'];
            $out[] = ($en ? 'Coach of the round: ' : 'مدرب الجولة: ')."{$c['coach']['name']} ({$c['club']} {$c['goals'][0]}-{$c['goals'][1]} {$c['opponent']})";
        }
        if ($e['team']) {
            $out[] = ($en ? 'Team of the round: ' : 'تشكيلة الجولة: ').implode('، ', array_map(fn ($p) => $p['name'], $e['team']));
        }
        foreach (array_slice($e['stories'], 0, 3) as $story) {
            $out[] = '- '.$story['title'];
        }

        return count($out) > 2 ? implode("\n", $out) : null;
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
