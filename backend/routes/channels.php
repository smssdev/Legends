<?php

use App\League\Members;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\DB;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// A league match: its league's members only (the owner and its coaches) [PLAN 2.13].
Broadcast::channel('match.{match}', function ($user, int $match) {
    $league = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')
        ->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->where('matches.id', $match)->value('seasons.league_id');

    return $league && Members::isMember($user->id, $league);
});

// A club's own channel: its coach only (his live readings, Sprint 20).
Broadcast::channel('club.{club}', fn ($user, int $club) => DB::table('clubs')->where('id', $club)->where('user_id', $user->id)->exists());
