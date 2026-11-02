<?php

namespace App\Notify;

use App\Models\User;
use App\Notifications\GameUpdateNotice;
use App\Support\Mailer;
use Illuminate\Support\Facades\DB;

/**
 * [X79] A coach's match summary by email (App\Notifications\GameUpdateNotice::matchSummary): only for an account that
 * turned it on in its notifications (notify_prefs.email_match, off by default) and confirmed its email, and only while
 * the server really sends email. Queued, so a match never waits on the mail server.
 */
class MatchEmail
{
    public static function wants(int $userId): bool
    {
        $prefs = json_decode((string) DB::table('users')->where('id', $userId)->value('notify_prefs'), true) ?: [];

        return ($prefs['email_match'] ?? false) === true;
    }

    /** @param  array  $state  the match's final state; $side the coach's side */
    public static function send(?int $userId, array $state, string $side, int $matchId, ?int $leagueId): bool
    {
        if (! $userId || ! Mailer::live() || ! self::wants($userId)) {
            return false;
        }
        $user = User::find($userId);
        if (! $user || ! $user->email || ! $user->email_verified_at) {
            return false;
        }
        $en = ($user->locale ?? 'ar') === 'en';
        $names = [];
        foreach (['home', 'away'] as $s) {
            foreach ($state['teams'][$s]['players'] as $p) {
                $names[$p['id']] = $p['name'];
            }
        }
        $scorers = DB::table('match_events')->where('match_id', $matchId)->where('type', 'goal')->orderBy('id')->get()
            ->map(fn ($e) => ($names[json_decode($e->payload, true)['scorer'] ?? 0] ?? '?')." {$e->minute}'")->all();
        $league = $leagueId ? (string) DB::table('leagues')->where('id', $leagueId)->value('name') : '';
        $user->notify(GameUpdateNotice::matchSummary($en, $state['teams']['home']['club']['name'], (int) $state['score']['home'],
            (int) $state['score']['away'], $state['teams']['away']['club']['name'], $league ?: ($en ? 'your league' : 'دوريك'), $scorers, $matchId));

        return true;
    }
}
