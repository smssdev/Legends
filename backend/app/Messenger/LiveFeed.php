<?php

namespace App\Messenger;

use App\Jobs\SendMessenger;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 68] A live match on the bots: a goal, a red card, half-time and the final whistle to the two coaches (where
 * they keep their live match on), and the goals to the league's Telegram group (where its owner keeps them on). Each
 * goes out when its minute's scene has ended on the screens (the runner makes minutes a little ahead), so the bot
 * never tells a goal before the match shows it. Only what the screens show to everyone: the score, the scorer, the card.
 */
class LiveFeed
{
    /** @param  array  $tick  the minute as the runner made it (its events, score, at and moment) */
    public static function minute(object $fixture, int $matchId, array $state, array $tick): void
    {
        // The live match never waits on the bots: anything wrong here is reported and the match goes on.
        try {
            self::send($fixture, $matchId, $state, $tick);
        } catch (\Throwable $e) {
            report($e);
        }
    }

    private static function send(object $fixture, int $matchId, array $state, array $tick): void
    {
        $notable = array_values(array_filter($tick['events'] ?? [], fn ($e) => match ($e['type']) {
            'goal' => true,
            'card' => ($e['color'] ?? '') === 'red',
            'period' => in_array($e['name'] ?? '', ['halftime', 'fulltime'], true),
            default => false,
        }));
        if (! $notable || (! Telegram::configured() && ! WhatsApp::configured())) {
            return;
        }
        $nowMs = GameClock::nowMs();
        $delay = (int) ceil(max(0, (int) ($tick['at'] ?? $nowMs) + (int) ($tick['moment']['ms'] ?? 0) - $nowMs) / 1000);
        $names = DB::table('clubs')->whereIn('id', [$fixture->home_id, $fixture->away_id])->pluck('name', 'id');
        $club = ['home' => $names[$fixture->home_id] ?? '', 'away' => $names[$fixture->away_id] ?? ''];
        $players = [];
        foreach (['home', 'away'] as $side) {
            foreach ($state['teams'][$side]['players'] ?? [] as $p) {
                $players[$p['id']] = $p['name'] ?? '';
            }
        }
        $minute = (int) ($tick['minute'] ?? 0);
        $url = rtrim((string) config('app.frontend_url'), '/')."/live/{$matchId}";
        $coaches = DB::table('clubs')->whereIn('id', [$fixture->home_id, $fixture->away_id])->whereNotNull('user_id')->pluck('user_id')->unique();
        $group = DB::table('messenger_groups')->join('seasons', 'seasons.league_id', '=', 'messenger_groups.league_id')
            ->where('seasons.id', $fixture->season_id)->where('messenger_groups.live', true)->first(['messenger_groups.chat_id', 'messenger_groups.league_id']);

        foreach ($notable as $e) {
            $text = fn (bool $en) => self::say($e, $club, $players, $minute, $en, $tick['score'] ?? null);
            foreach ($coaches as $userId) {
                Messenger::toUser((int) $userId, $text, fn (bool $en) => [[$en ? 'Open the match' : 'افتح المباراة', 'url:'.$url]], $delay, true);
            }
            if ($group && $e['type'] === 'goal' && Telegram::configured()) {
                $en = DB::table('leagues')->join('users', 'users.id', '=', 'leagues.owner_id')->where('leagues.id', $group->league_id)->value('users.locale') === 'en';
                SendMessenger::dispatch('telegram', $group->chat_id, $text($en))->delay($delay)->afterCommit();
            }
        }
    }

    /** One event in a line: what happened, who, the minute, and the score after it. */
    public static function say(array $e, array $club, array $players, int $minute, bool $en, ?array $tickScore = null): string
    {
        $score = $e['score'] ?? $tickScore;
        $line = $score ? "{$club['home']} {$score['home']} - {$score['away']} {$club['away']}" : '';
        $who = $players[$e['scorer'] ?? $e['player'] ?? 0] ?? '';
        $team = $club[$e['team'] ?? ''] ?? '';

        return match ($e['type']) {
            'goal' => ($en ? "Goal! {$who} ({$team}), minute {$minute}" : "هدف! {$who} ({$team})، الدقيقة {$minute}")."\n{$line}",
            'card' => $en ? "Sent off: {$who} ({$team}), minute {$minute}" : "طرد: {$who} ({$team})، الدقيقة {$minute}",
            default => ($e['name'] === 'halftime' ? ($en ? 'Half-time' : 'نهاية الشوط الأول') : ($en ? 'Full time' : 'نهاية المباراة'))
                .($line !== '' ? "\n{$line}" : ''),
        };
    }
}
