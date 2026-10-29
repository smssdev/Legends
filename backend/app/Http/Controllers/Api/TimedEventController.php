<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\GameClock;
use App\TimedEvents\TimedEvents;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The admin's timed events [Sprint 23]: none is permanent. The admin picks the kind, every league or one, the start
 * (now by default) and the end (at most game.timed_events.max_days later), and the power (and the special players'
 * count) within its kind's range; he may change the end and the power while it runs, end it early, or delete one
 * that has not started. What each kind does: App\TimedEvents\TimedEvents.
 */
class TimedEventController extends Controller
{
    public function index(): JsonResponse
    {
        $rows = DB::table('timed_events')->orderByDesc('ends_at')->orderByDesc('id')->limit(100)->get();
        $leagues = DB::table('leagues')->whereIn('id', $rows->pluck('league_id')->filter()->unique())->pluck('name', 'id');

        return response()->json(['events' => $rows->map(fn ($e) => $this->row($e, $leagues)),
            'kinds' => config('game.timed_events.kinds'), 'max_days' => (int) config('game.timed_events.max_days')]);
    }

    public function store(Request $request): JsonResponse
    {
        $kinds = config('game.timed_events.kinds');
        $data = $request->validate([
            'kind' => ['required', Rule::in(TimedEvents::KINDS)],
            'league_id' => ['nullable', 'integer', 'exists:leagues,id'],
            'starts_at' => ['nullable', 'date'],
            'ends_at' => ['required', 'date'],
            'power' => ['nullable', 'integer'],
            'count' => ['nullable', 'integer', 'min:1'],
        ]);
        $kind = $kinds[$data['kind']];
        $now = GameClock::now();
        $starts = isset($data['starts_at']) ? Carbon::parse($data['starts_at'])->utc() : $now->copy();
        $starts = $starts->lt($now) ? $now->copy() : $starts;
        $ends = Carbon::parse($data['ends_at'])->utc();
        $this->assertTimes($starts, $ends);
        $power = $this->power($kind, $data['power'] ?? null);
        $count = $this->count($kind, $data['count'] ?? null);
        $id = DB::table('timed_events')->insertGetId(['kind' => $data['kind'], 'league_id' => $data['league_id'] ?? null,
            'starts_at' => $starts, 'ends_at' => $ends, 'power' => $power, 'count' => $count, 'user_id' => $request->user()->id,
            'created_at' => $now, 'updated_at' => $now]);

        return response()->json(['event' => $this->row(DB::table('timed_events')->find($id))], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $e = DB::table('timed_events')->find($id);
        abort_unless($e, 404, __('الفعالية غير موجودة.'));
        abort_if(Carbon::parse($e->ends_at, 'UTC')->lte(GameClock::now()), 409, __('انتهت هذه الفعالية.'));
        $data = $request->validate(['ends_at' => ['sometimes', 'date'], 'power' => ['sometimes', 'integer'], 'count' => ['sometimes', 'integer', 'min:1']]);
        $kind = config("game.timed_events.kinds.{$e->kind}");
        $set = ['updated_at' => GameClock::now()];
        if (isset($data['ends_at'])) {
            $ends = Carbon::parse($data['ends_at'])->utc();
            $this->assertTimes(Carbon::parse($e->starts_at, 'UTC'), $ends);
            $set['ends_at'] = $ends;
        }
        if (isset($data['power'])) {
            $set['power'] = $this->power($kind, $data['power']);
        }
        if (isset($data['count'])) {
            $set['count'] = $this->count($kind, $data['count']);
        }
        DB::table('timed_events')->where('id', $id)->update($set);

        return response()->json(['event' => $this->row(DB::table('timed_events')->find($id))]);
    }

    /** One not started yet is deleted; one running ends now; one ended stays as a record. */
    public function destroy(int $id): JsonResponse
    {
        $e = DB::table('timed_events')->find($id);
        abort_unless($e, 404, __('الفعالية غير موجودة.'));
        $now = GameClock::now();
        abort_if(Carbon::parse($e->ends_at, 'UTC')->lte($now), 409, __('انتهت هذه الفعالية.'));
        if (Carbon::parse($e->starts_at, 'UTC')->gt($now)) {
            DB::table('timed_events')->where('id', $id)->delete();

            return response()->json(['ok' => true, 'deleted' => true]);
        }
        DB::table('timed_events')->where('id', $id)->update(['ends_at' => $now, 'updated_at' => $now]);

        return response()->json(['ok' => true, 'deleted' => false]);
    }

    private function assertTimes(Carbon $starts, Carbon $ends): void
    {
        $max = (int) config('game.timed_events.max_days');
        if ($ends->lte($starts) || $ends->lte(GameClock::now())) {
            throw new HttpException(422, __('موعد النهاية بعد البداية وبعد الآن.'));
        }
        if ($ends->gt($starts->copy()->addDays($max))) {
            throw new HttpException(422, sprintf(__('الفعالية مؤقتة: %d أيام على الأكثر.'), $max));
        }
    }

    private function power(array $kind, ?int $power): int
    {
        $power ??= (int) $kind['power'];
        if ($power < $kind['min'] || $power > $kind['max']) {
            throw new HttpException(422, sprintf(__('القوة من %d إلى %d.'), $kind['min'], $kind['max']));
        }

        return $power;
    }

    private function count(array $kind, ?int $count): int
    {
        if (! isset($kind['count'])) {
            return 0;
        }
        $count ??= (int) $kind['count'];
        if ($count > $kind['count_max']) {
            throw new HttpException(422, sprintf(__('عدد اللاعبين من 1 إلى %d.'), $kind['count_max']));
        }

        return $count;
    }

    private function row(object $e, $leagues = null): array
    {
        $now = GameClock::now();
        [$starts, $ends] = [Carbon::parse($e->starts_at, 'UTC'), Carbon::parse($e->ends_at, 'UTC')];
        $leagueName = $e->league_id ? ($leagues[$e->league_id] ?? DB::table('leagues')->where('id', $e->league_id)->value('name')) : null;

        return ['id' => $e->id, 'kind' => $e->kind, 'league' => $e->league_id ? ['id' => (int) $e->league_id, 'name' => $leagueName] : null,
            'starts_at' => $starts->toIso8601ZuluString(), 'ends_at' => $ends->toIso8601ZuluString(), 'power' => (int) $e->power, 'count' => (int) $e->count,
            'state' => $starts->gt($now) ? 'upcoming' : ($ends->gt($now) ? 'running' : 'ended')];
    }
}
