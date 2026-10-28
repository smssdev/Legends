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
 * The stadium [PLAN 2.9, Sprint 29; X7, 2026-10-24]: seats, tickets, pitch and training, three stages each, every
 * stage harder than the last (more parts, each longer, game.stadium.parts_by_stage and part_hours_by_stage), all
 * scaled by the season's length. The coach starts each part by hand and pays for it; it is done on time, coach
 * online or not. One part at a time across the whole stadium. A finished stage changes the game and the money: more
 * seats, dearer tickets, more home advantage and faster training, and the pitch and training draw more sponsor
 * money. A club left to the computer keeps what it built and finishes the part under way.
 */
class Stadium
{
    public const SECTIONS = ['seats', 'tickets', 'pitch', 'training'];

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

    /** The ticket price from the tickets section (basis points of the base price). */
    public static function ticketBp(int $clubId): int
    {
        return (int) config('game.stadium.ticket_price_bp_by_stage')[self::stage($clubId, 'tickets')];
    }

    /** The sponsors' money from the pitch and the training ground (basis points on top of the base). */
    public static function sponsorBp(int $clubId): int
    {
        $by = config('game.stadium.sponsor_bp_by_stage');

        return 10000 + (int) $by[self::stage($clubId, 'pitch')] + (int) $by[self::stage($clubId, 'training')];
    }

    /** The parts of a stage. */
    public static function partsIn(int $stage): int
    {
        return (int) config('game.stadium.parts_by_stage')[$stage];
    }

    /** Parts done in a section: every part of its finished stages, and those of the next. */
    public static function partsDone(int $stage, int $parts): int
    {
        $done = $parts;
        for ($s = 1; $s <= $stage; $s++) {
            $done += self::partsIn($s);
        }

        return $done;
    }

    /** Every part of a section. */
    public static function partsTotal(): int
    {
        return array_sum(config('game.stadium.parts_by_stage'));
    }

    /** A training session's step with the training section's speed on top, drawn by the session's key. */
    public static function trainingStep(int $clubId, int $step, string $key): int
    {
        [$lo, $hi] = config('game.stadium.training_speed_bp')[self::stage($clubId, 'training')];

        return intdiv($step * (10000 + $lo + crc32("stadium:{$key}") % ($hi - $lo + 1)), 10000);
    }

    /** Seconds one part of a stage takes in this league: longer each stage, and scaled by the season's length. */
    public static function partSeconds(int $leagueId, int $stage = 1): int
    {
        $scale = (int) DB::table('leagues')->where('id', $leagueId)->value('timer_scale');

        return max(60, intdiv((int) config('game.stadium.part_hours_by_stage')[$stage] * 3600 * ($scale ?: 10000), 10000));
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
                'ends_at' => $now->copy()->addSeconds(self::partSeconds($club->league_id, $stage)), 'status' => 'building',
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
            $stageDone = $b->part >= self::partsIn((int) $b->stage);
            DB::table('stadium_sections')->upsert([[
                'club_id' => $b->club_id, 'section' => $b->section,
                'stage' => $stageDone ? $b->stage : $b->stage - 1, 'parts' => $stageDone ? 0 : $b->part,
                'created_at' => $now, 'updated_at' => $now,
            ]], ['club_id', 'section'], ['stage', 'parts', 'updated_at']);
            $club = DB::table('clubs')->where('id', $b->club_id)->first();
            if ($club->user_id) {
                Inbox::send($club->user_id, 'stadium_part', ['section' => $b->section, 'stage' => (int) $b->stage, 'part' => (int) $b->part, 'parts' => self::partsIn((int) $b->stage), 'stage_done' => $stageDone],
                    $club->league_id, $club->id);
            }

            return true;
        });
    }
}
