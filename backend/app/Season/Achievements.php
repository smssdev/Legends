<?php

namespace App\Season;

use App\Auth\Referral;
use App\Messages\Inbox;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 30 G4] A coach's achievements (badges): worked out from what the game already keeps (the matches, the titles,
 * the rating's peak, the friendlies, the accepted ideas, the invites), with no table of their own, like the rating
 * (Sprint 25). Each has a goal (game.achievements) and the coach's progress toward it; one reached stays reached since
 * what it counts never goes down (the peak, not the points).
 * [Sprint 40 A1] Each has a level (beginner, intermediate, pro: game.achievement_tiers) and gives its coins once when
 * reached (game.achievement_rewards), by its own key in the wallet: award() pays what is reached and not yet paid.
 */
class Achievements
{
    /** @return list<array{key: string, goal: int, progress: int, earned: bool}> */
    public static function of(int $userId): array
    {
        $record = Career::record($userId);
        $trophies = Career::trophies($userId);
        $rating = CoachRating::of($userId);
        $tiers = config('game.rating.tiers');
        $counts = [
            'first_win' => $record['won'],
            'wins' => $record['won'],
            'matches' => $record['played'],
            'first_title' => $trophies['total'],
            'league_title' => $trophies['league'],
            'cup_title' => $trophies['cup'],
            // The highest tier the rating ever reached (its peak), as a step on the ladder.
            'professional' => (int) $rating['peak'],
            'legend' => (int) $rating['peak'],
            'friendlies' => DB::table('friendlies')->where('user_id', $userId)->count(),
            'idea' => DB::table('suggestions')->where('user_id', $userId)->whereIn('status', ['accepted', 'built'])->count(),
            'invites' => Referral::paid($userId),
            'matches_10' => $record['played'],
            'wins_100' => $record['won'],
            'titles_5' => $trophies['total'],
        ];
        $goals = config('game.achievements');
        $goals['professional'] = (int) $tiers['professional'];
        $goals['legend'] = (int) $tiers['legend'];
        $tiers = config('game.achievement_tiers');
        $rewards = config('game.achievement_rewards');
        $paid = DB::table('wallet_transactions')->where('user_id', $userId)->where('type', 'achievement')->pluck('reference')->flip();
        $out = [];
        foreach ($goals as $key => $goal) {
            $progress = min((int) ($counts[$key] ?? 0), (int) $goal);
            $tier = $tiers[$key] ?? 'beginner';
            $out[] = ['key' => $key, 'goal' => (int) $goal, 'progress' => $progress, 'earned' => $progress >= $goal,
                'tier' => $tier, 'reward' => (int) $rewards[$tier], 'paid' => isset($paid["achievement:{$key}"])];
        }

        return $out;
    }

    /** Pays the coins of every badge reached and not yet paid, once each, with a message. Returns the keys paid now. */
    public static function award(?int $userId): array
    {
        if (! $userId) {
            return [];
        }
        $now = [];
        foreach (self::of($userId) as $b) {
            if ($b['earned'] && ! $b['paid'] && $b['reward'] > 0) {
                Wallet::post($userId, 'achievement', $b['reward'], "achievement:{$userId}:{$b['key']}", "achievement:{$b['key']}");
                Inbox::send($userId, 'achievement', ['key' => $b['key'], 'tier' => $b['tier'], 'coins' => $b['reward']]);
                $now[] = $b['key'];
            }
        }

        return $now;
    }
}
