<?php

namespace App\Console\Commands;

use App\Messenger\Messenger;
use App\Season\CoachRating;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 67] The week's table of coaches by their points (Sprint 25), to the game's public channel: their in-game
 * usernames and points only.
 */
class MessengerWeekly extends Command
{
    protected $signature = 'messenger:weekly';

    protected $description = 'Post the weekly table of coaches to the public channel';

    public function handle(): int
    {
        $ids = DB::table('league_memberships')->whereNotNull('user_id')->whereNotNull('club_id')->distinct()->pluck('user_id')->unique();
        $rows = DB::table('users')->whereIn('id', $ids)->whereNotNull('username')->get(['id', 'username'])
            ->map(fn ($u) => ['username' => $u->username, 'points' => CoachRating::of((int) $u->id)['points']])
            ->sortByDesc('points')->take((int) config('game.messenger.weekly_top'))->values();
        if ($rows->isEmpty()) {
            $this->info('No coaches to post.');

            return self::SUCCESS;
        }
        $lines = ['ترتيب المدربين هذا الأسبوع (The coaches\' table this week):', ''];
        foreach ($rows as $i => $r) {
            $lines[] = sprintf('%d. %s: %d', $i + 1, $r['username'], $r['points']);
        }
        $lines[] = '';
        $lines[] = rtrim((string) config('app.frontend_url'), '/');
        Messenger::post('weekly', implode("\n", $lines));
        $this->info('Posted '.$rows->count().' coaches.');

        return self::SUCCESS;
    }
}
