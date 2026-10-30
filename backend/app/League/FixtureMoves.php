<?php

namespace App\League;

use App\Messages\Inbox;
use App\Models\Club;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * A match moved on its own day [Sprint 27 B2, the owner's request 2026-10-30]: a coach asks for his next match whole
 * hours earlier or later, on the same day in Cairo, and the other coach accepts or declines (a bot's club accepts at
 * once: nobody to ask). Both the old and the new time must be at least game.match_moves.lead_minutes away (so the
 * referee, the lock and the press conference keep their own times), the new one at least gap_minutes from any other
 * match of either club, and a fixture moves max_per_fixture times at most. One request waits at a time; it lapses
 * once either time comes within the lead. The fixture's time changes with one conditional update, so a lock or
 * another answer in the same moment wins and this one is refused.
 */
class FixtureMoves
{
    /** What the next-match screen shows: the request waiting, and the hours the coach may ask for now. */
    public static function view(object $fixture, Club $club): array
    {
        self::expire($fixture->id);
        $pending = DB::table('fixture_moves')->where('fixture_id', $fixture->id)->where('status', 'pending')->first();

        return [
            'pending' => $pending ? ['id' => (int) $pending->id, 'to_at' => self::iso($pending->to_at), 'mine' => (int) $pending->club_id === $club->id,
                'expires_at' => self::iso(Carbon::parse(min($pending->from_at, $pending->to_at), 'UTC')->subMinutes(self::lead()))] : null,
            'moves_left' => self::left($fixture),
            'hours' => $pending ? [] : self::hours($fixture),
        ];
    }

    /** The coach asks for the match $hours earlier (negative) or later. */
    public static function propose(Club $club, int $userId, int $fixtureId, int $hours): array
    {
        $f = self::fixture($club, $fixtureId);
        self::expire($f->id);
        abort_if(DB::table('fixture_moves')->where('fixture_id', $f->id)->where('status', 'pending')->exists(), 409, 'هناك طلب لم يُرد عليه بعد لهذه المباراة.');
        abort_if(self::left($f) < 1, 409, 'غُيّر موعد هذه المباراة أكثر مما يُسمح.');
        abort_unless(in_array($hours, self::hours($f), true), 422, 'هذا الموعد غير متاح: في اليوم نفسه، وبعيد عن مبارياتكما الأخرى، وقبل القفل بوقت كافٍ.');
        $from = Carbon::parse($f->scheduled_at, 'UTC');
        $to = $from->copy()->addHours($hours);
        $opponent = Club::find($f->home_id === $club->id ? $f->away_id : $f->home_id);
        $now = GameClock::now();
        $id = DB::table('fixture_moves')->insertGetId(['fixture_id' => $f->id, 'club_id' => $club->id, 'user_id' => $userId, 'from_at' => $from, 'to_at' => $to,
            'status' => 'pending', 'created_at' => $now, 'updated_at' => $now]);
        if (! $opponent->user_id) {
            // A bot's club: nobody to ask, so it is agreed at once.
            return self::decide($opponent, $id, true, null);
        }
        Inbox::send((int) $opponent->user_id, 'match_move', self::payload($f, $club, $to, 'asked'), $club->league_id, $opponent->id);

        return self::row(DB::table('fixture_moves')->find($id));
    }

    /** The other coach's answer: the match moves, or stays. */
    public static function answer(Club $club, int $userId, int $moveId, bool $accept): array
    {
        $move = DB::table('fixture_moves')->find($moveId);
        abort_unless($move, 404, 'لا يوجد هذا الطلب.');
        $f = self::fixture($club, (int) $move->fixture_id);
        abort_if((int) $move->club_id === $club->id, 403, 'الرد على الطلب للمدرب الآخر.');
        self::expire($f->id);

        return self::decide($club, $moveId, $accept, $userId);
    }

    /** The coach who asked takes it back. */
    public static function cancel(Club $club, int $moveId): void
    {
        $changed = DB::table('fixture_moves')->where('id', $moveId)->where('club_id', $club->id)->where('status', 'pending')
            ->update(['status' => 'cancelled', 'decided_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        abort_if($changed !== 1, 409, 'لا يوجد طلب ينتظر لتسحبه.');
    }

    /**
     * The hours (up to max_hours either way, never 0) the match may move by now: the same day in Cairo, both times at least the lead
     * away, and the new one at least gap_minutes from each club's other matches.
     *
     * @return list<int>
     */
    public static function hours(object $f): array
    {
        if ($f->status !== 'scheduled' || $f->is_bye || ! $f->home_id || ! $f->away_id || self::left($f) < 1) {
            return [];
        }
        $from = Carbon::parse($f->scheduled_at, 'UTC');
        $earliest = GameClock::now()->addMinutes(self::lead());
        if ($from->lt($earliest)) {
            return [];
        }
        $day = $from->copy()->setTimezone('Africa/Cairo')->toDateString();
        $gap = (int) config('game.match_moves.gap_minutes');
        $others = DB::table('fixtures')->where('id', '!=', $f->id)->where('is_bye', false)
            ->where(fn ($q) => $q->whereIn('home_id', [$f->home_id, $f->away_id])->orWhereIn('away_id', [$f->home_id, $f->away_id]))
            ->whereBetween('scheduled_at', [$from->copy()->subDay(), $from->copy()->addDay()])->pluck('scheduled_at')->map(fn ($t) => Carbon::parse($t, 'UTC'));
        $out = [];
        $most = (int) config('game.match_moves.max_hours');
        foreach (range(-$most, $most) as $h) {
            $to = $from->copy()->addHours($h);
            if ($h === 0 || $to->lt($earliest) || $to->copy()->setTimezone('Africa/Cairo')->toDateString() !== $day) {
                continue;
            }
            if ($others->contains(fn ($t) => abs($t->diffInMinutes($to, false)) < $gap)) {
                continue;
            }
            $out[] = $h;
        }

        return $out;
    }

    private static function decide(Club $club, int $moveId, bool $accept, ?int $userId): array
    {
        return DB::transaction(function () use ($club, $moveId, $accept, $userId) {
            $now = GameClock::now();
            $changed = DB::table('fixture_moves')->where('id', $moveId)->where('status', 'pending')
                ->update(['status' => $accept ? 'accepted' : 'declined', 'decided_by' => $userId, 'decided_at' => $now, 'updated_at' => $now]);
            abort_if($changed !== 1, 409, 'هذا الطلب لم يعد ينتظر رداً.');
            $move = DB::table('fixture_moves')->find($moveId);
            $f = DB::table('fixtures')->find($move->fixture_id);
            $asker = Club::find($move->club_id);
            if ($accept) {
                // Still at the asked-from time and not locked: else the answer comes too late.
                $moved = DB::table('fixtures')->where('id', $f->id)->where('status', 'scheduled')->where('scheduled_at', $move->from_at)
                    ->where('scheduled_at', '>', $now->copy()->addMinutes(self::lead()))
                    ->update(['scheduled_at' => $move->to_at, 'lock_at' => null, 'updated_at' => $now]);
                abort_if($moved !== 1 || Carbon::parse($move->to_at, 'UTC')->lt($now->copy()->addMinutes(self::lead())), 409, 'فات وقت تغيير موعد هذه المباراة.');
                // The season ends with its last match, wherever it moved.
                DB::table('seasons')->where('id', $f->season_id)->where('ends_at', '<', $move->to_at)->update(['ends_at' => $move->to_at]);
            }
            if ($asker->user_id && $userId) {
                Inbox::send((int) $asker->user_id, 'match_move', self::payload($f, $club, Carbon::parse($move->to_at, 'UTC'), $accept ? 'accepted' : 'declined'), $asker->league_id, $asker->id);
            }

            return self::row(DB::table('fixture_moves')->find($moveId));
        });
    }

    /** A request waiting once one of its times is within the lead has lapsed. */
    private static function expire(int $fixtureId): void
    {
        $edge = GameClock::now()->addMinutes(self::lead());
        DB::table('fixture_moves')->where('fixture_id', $fixtureId)->where('status', 'pending')
            ->where(fn ($q) => $q->where('from_at', '<', $edge)->orWhere('to_at', '<', $edge))
            ->update(['status' => 'expired', 'updated_at' => GameClock::now()]);
    }

    private static function fixture(Club $club, int $fixtureId): object
    {
        $f = DB::table('fixtures')->find($fixtureId);
        abort_unless($f && ((int) $f->home_id === $club->id || (int) $f->away_id === $club->id), 404, 'هذه ليست مباراة فريقك.');
        abort_if($f->status !== 'scheduled', 409, 'لا يتغير موعد مباراة قُفلت أو بدأت.');

        return $f;
    }

    private static function left(object $f): int
    {
        return max(0, (int) config('game.match_moves.max_per_fixture') - DB::table('fixture_moves')->where('fixture_id', $f->id)->where('status', 'accepted')->count());
    }

    private static function lead(): int
    {
        return (int) config('game.match_moves.lead_minutes');
    }

    private static function payload(object $f, Club $from, Carbon $to, string $what): array
    {
        return ['what' => $what, 'opponent' => $from->name, 'league' => DB::table('leagues')->where('id', $from->league_id)->value('name'),
            'league_id' => $from->league_id, 'fixture_id' => (int) $f->id, 'at' => $to->copy()->setTimezone('Africa/Cairo')->format('H:i')];
    }

    private static function row(object $m): array
    {
        return ['id' => (int) $m->id, 'fixture_id' => (int) $m->fixture_id, 'from_at' => self::iso($m->from_at), 'to_at' => self::iso($m->to_at), 'status' => $m->status];
    }

    private static function iso($t): string
    {
        return Carbon::parse($t, 'UTC')->toIso8601ZuluString();
    }
}
