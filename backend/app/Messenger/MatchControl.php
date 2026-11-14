<?php

namespace App\Messenger;

use App\League\MatchOrders;
use App\League\MatchRunner;
use App\League\Tactics;
use App\League\Timeouts;
use App\Models\Club;
use App\Simulator\CoachWindows;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

/**
 * [Sprint 69] A coach steers his live match from the bot: when a break for orders opens (the windows of X42), the bot
 * sends the game's quick orders (config game.quick_orders) and «جاهز». A tap gives the order exactly as the match screen
 * does (MatchOrders::give into the next minute, only while a window or a timeout is open), and «جاهز» is the screen's
 * ready button (MatchRunner::ready). Only his own side's tactics: nothing of the opponent's is read or shown.
 */
class MatchControl
{
    /** The buttons of a window: each quick order (q:<match>:<n>) and ready (ready:<match>). */
    public static function buttons(int $matchId, bool $en): array
    {
        $out = [];
        foreach (config('game.quick_orders') as $i => $o) {
            $out[] = [$en ? (self::EN[$o['label']] ?? $o['label']) : $o['label'], "q:{$matchId}:{$i}"];
        }
        $out[] = [$en ? 'Ready' : 'جاهز', "ready:{$matchId}"];

        return $out;
    }

    private const EN = ['هجوم كامل' => 'All-out attack', 'تأمين النتيجة' => 'Hold the result', 'ضغط عالٍ' => 'High press',
        'إبطاء اللعب' => 'Slow it down', 'استغلال الأطراف' => 'Use the wings', 'عودة للخطة' => 'Back to the plan'];

    /** A window opened in this minute: to each coach of the match (where he keeps his live match on). */
    public static function window(object $fixture, int $matchId, array $state, array $tick, int $delay): void
    {
        if (! CoachWindows::window($tick, $state['cfg']['match'] ?? [])) {
            return;
        }
        $minute = is_array($tick['minute'] ?? null) ? (int) $tick['minute'][0] : (int) ($tick['minute'] ?? 0);
        foreach (DB::table('clubs')->whereIn('id', [$fixture->home_id, $fixture->away_id])->whereNotNull('user_id')->pluck('user_id')->unique() as $userId) {
            Messenger::toUser((int) $userId, fn (bool $en) => $en
                ? "Break at minute {$minute}: give an order, or tap Ready to play on."
                : "توقف الدقيقة {$minute}: أعطِ أمراً، أو اضغط «جاهز» ليُستأنف اللعب.",
                fn (bool $en) => self::buttons($matchId, $en), $delay, true);
        }
    }

    /** A tapped q:<match>:<n> or ready:<match> from this account. */
    public static function run(int $userId, string $data, bool $en): string
    {
        $parts = explode(':', $data);
        $matchId = (int) ($parts[1] ?? 0);
        $m = DB::table('matches')->where('id', $matchId)->first();
        $f = $m ? DB::table('fixtures')->where('id', $m->fixture_id)->first() : null;
        $club = $f ? Club::whereIn('id', [$f->home_id, $f->away_id])->where('user_id', $userId)->first() : null;
        if (! $club || $m->mode !== 'live' || $m->status !== 'live') {
            return $en ? 'This match is not yours, or it is over.' : 'هذه المباراة ليست لك، أو انتهت.';
        }
        $side = (int) $club->id === (int) $f->home_id ? 'home' : 'away';
        MatchOrders::watching($m->id, $side);
        try {
            if ($parts[0] === 'ready') {
                MatchRunner::ready($m->id, $side);

                return $en ? 'Ready: play goes on once both coaches are.' : 'جاهز: يُستأنف اللعب حين يجهز المدربان.';
            }
            $order = config('game.quick_orders')[(int) ($parts[2] ?? -1)] ?? null;
            if (! $order) {
                return $en ? 'This button is no longer valid.' : 'هذا الزر لم يعد صالحاً.';
            }
            $state = Cache::get("league-match:{$m->id}")['state'] ?? json_decode($m->state, true);
            if (! (CoachWindows::open($state) || Timeouts::active($m->id))) {
                return $en ? 'Orders only in a break: before kick-off, at half-time, and at minutes 15, 30, 60 and 75.' : 'التغيير في فترات التوقف فقط: قبل البداية، وفي الدقائق 15 و30 و45 و60 و75.';
            }
            $tick = max((int) $m->tick, (int) ($state['tick'] ?? 0)) + 1;
            // «عودة للخطة»: the club's own tactics as saved before the match.
            $tactics = $order['tactics'] ?? Tactics::of($club);
            MatchOrders::give($m->id, $side, $userId, "bot:{$m->id}:{$tick}:".($parts[2] ?? ''), ['type' => 'tactics', 'tactics' => $tactics], $tick);
        } catch (HttpExceptionInterface $e) {
            return $e->getMessage();
        }

        return $en ? 'Order given: «'.(self::EN[$order['label']] ?? $order['label']).'» from the next minute.' : "أُعطي الأمر «{$order['label']}» من الدقيقة التالية.";
    }
}
