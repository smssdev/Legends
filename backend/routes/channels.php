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

// [Sprint 29] A chat group: its members only.
Broadcast::channel('chat.{group}', fn ($user, int $group) => DB::table('chat_group_members')->where('chat_group_id', $group)->where('user_id', $user->id)->exists());

// [X66] A tournament's live draw: anyone signed in may watch it, and its chat with it.
Broadcast::channel('draw.{league}', fn ($user, int $league) => DB::table('leagues')->where('id', $league)->where('kind', 'tournament')->exists());
