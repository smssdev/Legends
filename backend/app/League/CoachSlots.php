<?php

namespace App\League;

use App\Messages\Inbox;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The coach's slots [Sprint 24 B3, the owner's request 2026-10-29]: game.league.max_active_teams (8) in all,
 * game.league.slots.open (2) open from the day the account is made, and one more every slots.every_days (10) of
 * the account's age, so all 8 on day 60. Or at once for coins (slots.unlock_coins: 50 for the third up to 300 for
 * the eighth), in order only, and for good (users.slots_unlocked). A team held before this stays, even past the
 * open slots; the coach only waits (or pays) for a free open slot to take a new one.
 */
class CoachSlots
{
    /** How many slots are open for this account now. */
    public static function open(User $user): int
    {
        return max(self::openAt(Carbon::parse($user->created_at, 'UTC'), GameClock::now()), min((int) config('game.league.max_active_teams'), (int) $user->slots_unlocked));
    }

    /** The coins to open every slot after the open ones up to $slot at once (in order), or null for none to buy. */
    public static function price(User $user, int $slot): ?int
    {
        $open = self::open($user);
        if ($slot <= $open || $slot > (int) config('game.league.max_active_teams')) {
            return null;
        }
        $prices = config('game.league.slots.unlock_coins');

        return array_sum(array_map(fn ($n) => (int) $prices[$n], range($open + 1, $slot)));
    }

    /**
     * Open the slots up to $slot now for coins [Sprint 24 B3]: those before it with it, so never one out of order.
     * The coins and the slot in one write, once by the slot (a repeated tap pays once); never closes again.
     */
    public static function unlock(User $user, int $slot): void
    {
        $price = self::price($user, $slot);
        if ($price === null) {
            throw new HttpException(409, __('هذه الفتحة مفتوحة أو ليست فتحة تُشترى.'));
        }
        DB::transaction(function () use ($user, $slot, $price) {
            $moved = DB::table('users')->where('id', $user->id)
                ->where(fn ($q) => $q->whereNull('slots_unlocked')->orWhere('slots_unlocked', '<', $slot))
                ->update(['slots_unlocked' => $slot]);
            if ($moved !== 1) {
                return;
            }
            Wallet::post($user->id, 'slot_unlock', -$price, "slot:{$user->id}:{$slot}", "slot:{$slot}");
            // Bought, not waited for: no message that it opened.
            DB::table('users')->where('id', $user->id)->whereNotNull('slots_notified')->where('slots_notified', '<', $slot)->update(['slots_notified' => $slot]);
        });
        $user->slots_unlocked = $slot;
    }

    /** How far the wait for a locked slot has gone, in bp (from the account's first day to the slot's). */
    public static function progressBp(User $user, int $slot): int
    {
        $created = Carbon::parse($user->created_at, 'UTC');
        $span = self::opensAt($created, $slot)->getTimestamp() - $created->getTimestamp();

        return $span <= 0 ? 10000 : min(10000, intdiv(max(0, GameClock::now()->getTimestamp() - $created->getTimestamp()) * 10000, $span));
    }

    /** The pure count: the slots open at $now for an account made at $created. */
    public static function openAt(Carbon $created, Carbon $now): int
    {
        $cfg = config('game.league.slots');
        $days = $created->gt($now) ? 0 : intdiv($now->getTimestamp() - $created->getTimestamp(), 86400);

        return min((int) config('game.league.max_active_teams'), (int) $cfg['open'] + intdiv($days, (int) $cfg['every_days']));
    }

    /** When slot number $slot (1-based) opens for an account made at $created. */
    public static function opensAt(Carbon $created, int $slot): Carbon
    {
        $cfg = config('game.league.slots');

        return $created->copy()->addDays(max(0, $slot - (int) $cfg['open']) * (int) $cfg['every_days']);
    }

    /** When the next slot opens, or null when all are open. */
    public static function next(User $user): ?Carbon
    {
        $open = self::open($user);

        return $open >= (int) config('game.league.max_active_teams') ? null : self::opensAt(Carbon::parse($user->created_at, 'UTC'), $open + 1);
    }

    /**
     * Tell each young account once for each slot that opened [Sprint 24]: a message in the inbox (and its push).
     * An account counted for the first time is only counted, so no one hears of slots that were always open.
     * The count moves by a conditional update, so two runs at once announce a slot once.
     */
    public static function announce(): int
    {
        $max = (int) config('game.league.max_active_teams');
        $told = 0;
        // An account counted at the top has nothing left to hear.
        foreach (User::whereNull('slots_notified')->orWhere('slots_notified', '<', $max)->get(['id', 'created_at', 'slots_notified', 'slots_unlocked']) as $user) {
            $open = self::open($user);
            $was = $user->slots_notified === null ? null : (int) $user->slots_notified;
            if ($was !== null && $open <= $was) {
                continue;
            }
            DB::transaction(function () use ($user, $open, $was, &$told) {
                $moved = DB::table('users')->where('id', $user->id)
                    ->where(fn ($q) => $was === null ? $q->whereNull('slots_notified') : $q->where('slots_notified', $was))
                    ->update(['slots_notified' => $open]);
                if ($moved === 1 && $was !== null) {
                    $next = self::next($user);
                    Inbox::send($user->id, 'slot_opened', ['slot' => $open, 'open' => $open, 'max' => (int) config('game.league.max_active_teams'),
                        'next_at' => $next?->toIso8601ZuluString()]);
                    $told++;
                }
            });
        }

        return $told;
    }
}
