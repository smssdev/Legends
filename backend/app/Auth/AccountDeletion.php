<?php

namespace App\Auth;

use App\League\Leaving;
use App\Models\LeagueMembership;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/** An account goes, with everything that is only its own; its clubs go back to the bots [PLAN 2.17, UP13]. */
class AccountDeletion
{
    public static function delete(User $user): void
    {
        DB::transaction(function () use ($user) {
            $user->tokens()->delete();
            Sessions::forget($user->id);
            if ($user->email !== null) {
                DB::table('password_reset_tokens')->where('email', $user->email)->delete();
            }
            // Its clubs go back to the bots, as any coach leaving: offers and listings cancelled [PLAN 2.2, Sprint 37].
            foreach (LeagueMembership::where('user_id', $user->id)->whereNull('left_at')->get() as $m) {
                Leaving::leave($m, 'deleted');
            }
            // What is only its own goes with it (wallet, messages, devices, activity: by the database's cascades);
            // what the leagues keep (titles, objectives, matches) loses the name.
            $user->delete();
        });
    }
}
