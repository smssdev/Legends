<?php

namespace App\Stadium;

use App\Economy\Economy;
use App\League\ClubLedger;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The stadium [PLAN 2.9, Sprint 29]: seats, pitch and training, three stages of five parts each. The coach starts
 * each part by hand and pays for it; it is done in 20 hours in every league [Sprint 21 E6], coach online or not.
 * One part at a time across the whole stadium. A finished stage changes the game: more seats (and tickets), more
 * home advantage, faster training. A club left to the computer keeps what it built and finishes the part under way.
 */
class Stadium
{
    public const SECTIONS = ['seats', 'pitch', 'training'];

    /** The stage each section has reached. [section => 0..3] */
    public static function stages(int $clubId): array
    {
        $rows = DB::table('stadium_sections')->where('club_id', $clubId)->pluck('stage', 'section');

        return array_combine(self::SECTIONS, array_map(fn ($s) => (int) ($rows[$s] ?? 0), self::SECTIONS));
    }

    public static function stage(int $clubId, string $section): int
    {
        return (int) DB::table('stadium_sections')->where('club_id', $clubId)->where('section', $section)->value('stage');
    }

    public static function capacity(int $clubId): int
    {
        return (int) config('game.stadium.capacity_by_stage')[self::stage($clubId, 'seats')];
    }

    /** A training session's step with the training section's speed on top, drawn by the session's key. */
    public static function trainingStep(int $clubId, int $step, string $key): int
    {
        [$lo, $hi] = config('game.stadium.training_speed_bp')[self::stage($clubId, 'training')];

        return intdiv($step * (10000 + $lo + crc32("stadium:{$key}") % ($hi - $lo + 1)), 10000);
    }

    /** Seconds one part takes in this league. */
    public static function partSeconds(int $leagueId): int
    {
        // [Sprint 21 E6] The same in every league (no longer scaled by the season's length).
        return max(60, (int) config('game.stadium.part_hours') * 3600);
    }

    /** The next part of a section: [stage, part], or null when the section is finished. */
    public static function nextPart(int $clubId, string $section): ?array
    {
        $row = DB::table('stadium_sections')->where('club_id', $clubId)->where('section', $section)->first();
        $stage = (int) ($row->stage ?? 0);

        return $stage >= (int) config('game.stadium.stages') ? null : [$stage + 1, (int) ($row->parts ?? 0) + 1];
    }

    public static function partCost(int $leagueId, int $stage): int
    {
        return intdiv(Economy::scale($leagueId) * (int) config('game.stadium.part_cost_bp')[$stage], 10000);
    }

    public static function building(int $clubId): ?object
    {
        return DB::table('stadium_builds')->where('club_id', $clubId)->where('status', 'building')->first();
    }

    /** Start the next part of a section. */
    public static function start(int $clubId, string $section, string $key): void
    {
        DB::transaction(function () use ($clubId, $section, $key) {
            if (DB::table('stadium_builds')->where('idempotency_key', $key)->exists()) {
                return;
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            $next = self::nextPart($clubId, $section);
            if (! $next) {
                throw new HttpException(409, 'هذا القسم مكتمل.');
            }
            [$stage, $part] = $next;
            $cost = self::partCost($club->league_id, $stage);
            $now = GameClock::now();
            // One part at a time across the stadium (the IMMEDIATE transaction keeps two starts apart).
            if (self::building($clubId)) {
                throw new HttpException(409, 'يُبنى جزء الآن، انتظر حتى يكتمل.');
            }
            $id = DB::table('stadium_builds')->insertGetId([
                'club_id' => $clubId, 'section' => $section, 'stage' => $stage, 'part' => $part, 'cost' => $cost,
                'ends_at' => $now->copy()->addSeconds(self::partSeconds($club->league_id)), 'status' => 'building',
                'idempotency_key' => $key, 'created_at' => $now, 'updated_at' => $now,
            ]);
            ClubLedger::post($clubId, 'stadium', -$cost, "stadium:{$id}", "stadium:{$section}:{$stage}:{$part}", spend: true);
        });
    }

    /** Every minute: the parts whose time has come. */
    public static function due(): int
    {
        $n = 0;
        foreach (DB::table('stadium_builds')->where('status', 'building')->where('ends_at', '<=', GameClock::now())->pluck('id') as $id) {
            $n += self::finish((int) $id) ? 1 : 0;
        }

        return $n;
    }

    public static function finish(int $buildId): bool
    {
        return DB::transaction(function () use ($buildId) {
            $b = DB::table('stadium_builds')->where('id', $buildId)->first();
            if (! $b || Carbon::parse($b->ends_at, 'UTC')->gt(GameClock::now())
                || DB::table('stadium_builds')->where('id', $buildId)->where('status', 'building')->update(['status' => 'done', 'updated_at' => GameClock::now()]) !== 1) {
                return false;
            }
            $now = GameClock::now();
            $stageDone = $b->part >= (int) config('game.stadium.parts_per_stage');
            DB::table('stadium_sections')->upsert([[
                'club_id' => $b->club_id, 'section' => $b->section,
                'stage' => $stageDone ? $b->stage : $b->stage - 1, 'parts' => $stageDone ? 0 : $b->part,
                'created_at' => $now, 'updated_at' => $now,
            ]], ['club_id', 'section'], ['stage', 'parts', 'updated_at']);
            $club = DB::table('clubs')->where('id', $b->club_id)->first();
            if ($club->user_id) {
                Inbox::send($club->user_id, 'stadium_part', ['section' => $b->section, 'stage' => (int) $b->stage, 'part' => (int) $b->part, 'stage_done' => $stageDone],
                    $club->league_id, $club->id);
            }

            return true;
        });
    }
}
