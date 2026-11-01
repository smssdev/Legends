<?php

namespace App\Season;

use App\Auth\Referral;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 30 G4] A coach's achievements (badges): worked out from what the game already keeps (the matches, the titles,
 * the rating's peak, the friendlies, the accepted ideas, the invites), with no table of their own, like the rating
 * (Sprint 25). Each has a goal (game.achievements) and the coach's progress toward it; one reached stays reached since
 * what it counts never goes down (the peak, not the points).
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
        ];
        $goals = config('game.achievements');
        $goals['professional'] = (int) $tiers['professional'];
        $goals['legend'] = (int) $tiers['legend'];
        $out = [];
        foreach ($goals as $key => $goal) {
            $progress = min((int) ($counts[$key] ?? 0), (int) $goal);
            $out[] = ['key' => $key, 'goal' => (int) $goal, 'progress' => $progress, 'earned' => $progress >= $goal];
        }

        return $out;
    }
}
