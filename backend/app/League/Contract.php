<?php

namespace App\League;

use App\Data\Crests;
use App\Models\League;
use App\Models\LeagueMembership;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 43 W1, Hamza 2026-11-05] The contract a coach signs when he takes his club, once a season: the club, the
 * league and its season, the board's objective (App\Season\Objectives) and the money to spend. The signature is drawn
 * on the screen and never sent or kept: only the time it was signed (league_contracts).
 */
class Contract
{
    /** The contract waiting for this coach's signature in this league, or null (signed, or nothing to sign yet). */
    public static function pending(League $league, LeagueMembership $m): ?array
    {
        if (! $m->club_id || ! $league->season || $league->kind === 'tournament') {
            return null;
        }
        if (DB::table('league_contracts')->where('season_id', $league->season->id)->where('user_id', $m->user_id)->exists()) {
            return null;
        }
        $club = DB::table('clubs')->where('id', $m->club_id)->first(['id', 'master_club_id', 'name', 'code', 'balance', 'color_primary', 'color_secondary']);
        $objectives = DB::table('club_objectives')->where('club_id', $m->club_id)->where('season_id', $league->season->id)->get()->keyBy('competition');
        $goal = $objectives['league'] ?? null;

        return ['club' => ['id' => (int) $club->id, 'name' => $club->name, 'code' => $club->code,
            'colors' => [$club->color_primary, $club->color_secondary], 'crest_url' => Crests::url($club->master_club_id)],
            'league' => $league->name, 'season' => (int) $league->season->number,
            'objective' => $goal ? ['kind' => $goal->kind, 'target' => (int) $goal->target] : null,
            'cup' => isset($objectives['cup']) ? $objectives['cup']->target : null,
            'budget' => (int) $club->balance];
    }

    /** The coach signs: once a season, for the club he coaches now. */
    public static function sign(League $league, LeagueMembership $m): void
    {
        if (! $m->club_id || ! $league->season) {
            throw new HttpException(409, 'لا فريق لك في هذا الدوري الآن.');
        }
        DB::table('league_contracts')->insertOrIgnore(['league_id' => $league->id, 'season_id' => $league->season->id, 'user_id' => $m->user_id,
            'club_id' => $m->club_id, 'signed_at' => GameClock::now()]);
    }
}
