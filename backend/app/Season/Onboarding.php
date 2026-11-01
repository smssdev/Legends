<?php

namespace App\Season;

use App\Models\User;
use App\Staff\Specialists;
use Illuminate\Support\Facades\DB;

/**
 * [X75] A new coach's first steps as done in the game, never by a tap on them (the owner's report 2026-11-01): each
 * one is checked from what the server keeps.
 *  - account: verified (the code) or tied to Google.
 *  - invite: another coach in one of my leagues (with a club, or accepted and still choosing), or a friend signed up
 *    from my link.
 *  - coach: a line coach hired for one of my clubs, ever.
 *  - lineup: a lineup saved by the coach himself (the assistant's pick is not saved).
 *  - tactics: tactics saved by the coach.
 *  - name: a picture of his own (uploaded, or Google's).
 *  - friendly: a friendly played.
 */
class Onboarding
{
    /** @return array<string, bool> */
    public static function of(User $user): array
    {
        $clubs = DB::table('clubs')->where('user_id', $user->id)->pluck('id');
        $leagues = DB::table('clubs')->where('user_id', $user->id)->pluck('league_id')
            ->merge(DB::table('leagues')->where('owner_id', $user->id)->pluck('id'))->unique();

        return [
            'account' => $user->account_verified_at !== null || $user->google_id !== null,
            'invite' => DB::table('clubs')->whereIn('league_id', $leagues)->whereNotNull('user_id')->where('user_id', '!=', $user->id)->exists()
                || DB::table('league_join_requests')->whereIn('league_id', $leagues)->where('status', 'approved')->where('user_id', '!=', $user->id)->exists()
                || DB::table('users')->where('referred_by', $user->id)->exists(),
            'coach' => DB::table('staff_specialists')->whereIn('club_id', $clubs)->whereIn('type', array_values(Specialists::LINE_COACH))->exists(),
            'lineup' => DB::table('lineups')->whereIn('club_id', $clubs)->exists(),
            'tactics' => DB::table('tactics')->whereIn('club_id', $clubs)->exists(),
            'name' => $user->avatarUrl() !== null,
            'friendly' => DB::table('friendlies')->where('user_id', $user->id)->exists(),
        ];
    }
}
