<?php

namespace App\Auth;

use App\Messages\Inbox;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * An account's holidays and its inactivity [UP13, the owner's spec 7, 2026-10-26].
 *
 * The coach gives the days and the reason. Up to game.account.auto_vacation_days it starts at once, twice in a
 * season at most with a few days' rest between; a longer one waits for the developers (the admin panel), who
 * approve or refuse it, and the coach is told. A holiday protects the account from deletion and its leagues
 * from its absence (Presence). An account not used for game.inactivity.inactive_days in a row, with no holiday,
 * is deleted with its teams; it is warned at warn_after_days, by a message and a push.
 */
class AccountHolidays
{
    /** Returns the holiday's row: auto (started) or pending (for the developers). */
    public static function request(User $user, int $days, string $reason): object
    {
        $cfg = config('game.account');
        $now = GameClock::now();
        $user = $user->fresh();
        abort_if($user->onVacation($now), 409, 'أنت في إجازة الآن.');
        abort_if(DB::table('account_vacations')->where('user_id', $user->id)->where('status', 'pending')->exists(), 409, 'طلب إجازتك الطويلة ينتظر رد فريق التطوير.');
        if ($days > (int) $cfg['auto_vacation_days']) {
            $id = DB::table('account_vacations')->insertGetId(['user_id' => $user->id, 'days' => $days, 'reason' => $reason, 'status' => 'pending',
                'created_at' => $now, 'updated_at' => $now]);
            foreach (User::where('role', 'admin')->pluck('id') as $admin) {
                Inbox::send($admin, 'account_vacation_request', ['name' => $user->name, 'username' => $user->username, 'days' => $days, 'reason' => $reason, 'id' => $id]);
            }

            return DB::table('account_vacations')->find($id);
        }
        $season = $now->copy()->subDays((int) config('game.league.reference_season_days'));
        $recent = DB::table('account_vacations')->where('user_id', $user->id)->where('status', 'auto')->where('starts_at', '>=', $season)->orderByDesc('starts_at')->get();
        if ($recent->count() >= (int) $cfg['auto_vacations_per_season']) {
            throw new HttpException(409, 'استخدمت إجازتيك القصيرتين لهذا الموسم. اطلب إجازة أطول من 5 أيام ليراجعها فريق التطوير.');
        }
        $last = $recent->first();
        if ($last && GameClock::now()->lt(Carbon::parse($last->ends_at, 'UTC')->addDays((int) $cfg['vacation_cooldown_days']))) {
            throw new HttpException(409, 'تُتاح إجازتك التالية بعد '.$cfg['vacation_cooldown_days'].' أيام من نهاية السابقة.');
        }

        return self::start($user, $days, $reason, 'auto');
    }

    /** The developers' answer to a long holiday. */
    public static function decide(int $id, User $by, bool $approve): object
    {
        $now = GameClock::now();
        $row = DB::table('account_vacations')->find($id);
        abort_unless($row, 404);
        $changed = DB::table('account_vacations')->where('id', $id)->where('status', 'pending')
            ->update(['status' => $approve ? 'approved' : 'rejected', 'decided_by' => $by->id, 'decided_at' => $now, 'updated_at' => $now]);
        abort_if($changed !== 1, 409, 'قُرر في هذا الطلب من قبل.');
        $user = User::findOrFail($row->user_id);
        if ($approve) {
            self::begin($user, (int) $row->days, $id);
        }
        Inbox::send($user->id, 'account_vacation', ['status' => $approve ? 'approved' : 'rejected', 'days' => (int) $row->days]);

        return DB::table('account_vacations')->find($id);
    }

    private static function start(User $user, int $days, string $reason, string $status): object
    {
        $now = GameClock::now();
        $id = DB::table('account_vacations')->insertGetId(['user_id' => $user->id, 'days' => $days, 'reason' => $reason, 'status' => $status,
            'created_at' => $now, 'updated_at' => $now]);
        self::begin($user, $days, $id);
        Inbox::send($user->id, 'account_vacation', ['status' => $status, 'days' => $days]);

        return DB::table('account_vacations')->find($id);
    }

    /** The holiday starts now: the account's dates (every league reads them) and the row's. */
    private static function begin(User $user, int $days, int $id): void
    {
        $now = GameClock::now();
        $until = $now->copy()->addDays($days);
        DB::table('users')->where('id', $user->id)->update(['vacation_from' => $now, 'vacation_until' => $until, 'inactive_warned_at' => null, 'updated_at' => $now]);
        DB::table('account_vacations')->where('id', $id)->update(['starts_at' => $now, 'ends_at' => $until, 'updated_at' => $now]);
        DB::table('league_memberships')->where('user_id', $user->id)->whereNull('left_at')->update(['absence_warned_at' => null, 'last_active_at' => $now]);
    }

    /** When the account was last used: its last day of activity, its making, or the end of its last holiday. */
    public static function lastSeen(User $user): Carbon
    {
        $day = DB::table('user_activity')->where('user_id', $user->id)->max('day');
        $dates = array_filter([
            $day ? Carbon::parse($day, 'Africa/Cairo')->endOfDay()->utc() : null,
            $user->created_at, $user->vacation_until,
        ]);

        return collect($dates)->max();
    }

    /**
     * Every day: the accounts unused for warn_after_days are told (once), and those unused for inactive_days are
     * deleted. Never one on holiday, an admin's, or a developer's official account. Returns [warned, deleted].
     */
    public static function sweep(): array
    {
        $now = GameClock::now();
        $cfg = config('game.inactivity');
        [$warned, $deleted] = [0, 0];
        foreach (User::where('role', '!=', 'admin')->orderBy('id')->cursor() as $user) {
            if ($user->onVacation($now) || Username::official($user->username)) {
                continue;
            }
            $idle = (int) self::lastSeen($user)->diffInDays($now, true);
            if ($idle >= (int) $cfg['inactive_days']) {
                AccountDeletion::delete($user);
                $deleted++;
            } elseif ($idle >= (int) $cfg['warn_after_days'] && $user->inactive_warned_at === null) {
                DB::table('users')->where('id', $user->id)->update(['inactive_warned_at' => $now]);
                Inbox::send($user->id, 'inactive_warning', ['days' => $idle, 'left' => (int) $cfg['inactive_days'] - $idle]);
                $warned++;
            }
        }

        return [$warned, $deleted];
    }
}
