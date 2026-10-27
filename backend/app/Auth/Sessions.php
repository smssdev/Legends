<?php

namespace App\Auth;

use Illuminate\Support\Facades\DB;

/** The web sessions, wherever they are kept (the game's database, or the server's own file on Render [X45]). */
class Sessions
{
    /** Signs an account out of every browser. */
    public static function forget(int $userId): void
    {
        DB::connection(config('session.connection'))->table(config('session.table', 'sessions'))->where('user_id', $userId)->delete();
    }
}
