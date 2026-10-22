<?php

namespace App\Messages;

use App\Events\MessageReceived;
use App\Events\MessagesRead;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The inbox [Sprint 22]: a message is kept for its account and sent at once on the account's private
 * channel (after the transaction it was made in commits). Reading it on one screen marks it read on the
 * others the same moment.
 */
class Inbox
{
    public static function send(?int $userId, string $type, array $payload, ?int $leagueId = null, ?int $clubId = null): ?int
    {
        if (! $userId) {
            return null;
        }
        $id = DB::table('messages')->insertGetId(['user_id' => $userId, 'league_id' => $leagueId, 'club_id' => $clubId,
            'type' => $type, 'payload' => json_encode($payload, JSON_UNESCAPED_UNICODE), 'created_at' => GameClock::now()]);
        MessageReceived::dispatch($userId, self::view(DB::table('messages')->find($id)), self::unread($userId));

        return $id;
    }

    /** The coach of a club in a league (null for a bot's). */
    public static function coachOf(?int $clubId): ?int
    {
        return $clubId ? DB::table('clubs')->where('id', $clubId)->value('user_id') : null;
    }

    public static function unread(int $userId): int
    {
        return DB::table('messages')->where('user_id', $userId)->whereNull('read_at')->count();
    }

    /** Mark read: some ids, or all. Returns the ids that changed. */
    public static function read(int $userId, ?array $ids = null): array
    {
        $q = DB::table('messages')->where('user_id', $userId)->whereNull('read_at');
        if ($ids !== null) {
            $q->whereIn('id', $ids);
        }
        $changed = $q->pluck('id')->all();
        if ($changed) {
            DB::table('messages')->whereIn('id', $changed)->whereNull('read_at')->update(['read_at' => GameClock::now()]);
            MessagesRead::dispatch($userId, $changed, self::unread($userId));
        }

        return $changed;
    }

    public static function view(object $m): array
    {
        return ['id' => $m->id, 'type' => $m->type, 'league_id' => $m->league_id, 'read' => $m->read_at !== null,
            'created_at' => Carbon::parse($m->created_at, 'UTC')->toIso8601ZuluString()]
            + MessageText::render($m->type, json_decode($m->payload, true) ?? []);
    }
}
