<?php

namespace App\Http\Controllers\Api;

use App\Admin\Conversations;
use App\Admin\TwoFactor;
use App\Auth\AccountDeletion;
use App\Auth\AccountHolidays;
use App\Auth\AccountVerification;
use App\Auth\Sessions;
use App\Auth\Username;
use App\Console\Commands\MatchesLive;
use App\Http\Controllers\Controller;
use App\League\Alliance;
use App\Messages\Inbox;
use App\Models\User;
use App\Simulator\Commentary;
use App\Support\Activity;
use App\Support\GameClock;
use App\Support\Mailer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/**
 * The admin panel [PLAN 2.17, 2.22, Sprint 37]: for the admin only, after the two-step code. The users, the
 * leagues, the backups, the commentary templates, and the activity and return indicators.
 */
class AdminController extends Controller
{
    private function adminOnly(Request $request): void
    {
        abort_unless($request->user()?->isAdmin(), 403, 'لوحة الإدارة للمدير فقط.');
    }

    /** Where the admin stands: two-step set up? passed in this session? */
    public function status(Request $request): JsonResponse
    {
        $this->adminOnly($request);

        return response()->json(['required' => TwoFactor::required(), 'enabled' => (bool) $request->user()->two_factor_enabled_at, 'passed' => TwoFactor::passed()]);
    }

    public function setup(Request $request): JsonResponse
    {
        $this->adminOnly($request);

        return response()->json(TwoFactor::setup($request->user()));
    }

    public function confirm(Request $request): JsonResponse
    {
        $this->adminOnly($request);
        TwoFactor::confirm($request->user(), (string) $request->validate(['code' => 'required|string|max:10'])['code']);

        return $this->status($request);
    }

    public function verify(Request $request): JsonResponse
    {
        $this->adminOnly($request);
        TwoFactor::verify($request->user(), (string) $request->validate(['code' => 'required|string|max:10'])['code']);

        return $this->status($request);
    }

    public function overview(): JsonResponse
    {
        $today = GameClock::now()->setTimezone('Africa/Cairo')->toDateString();

        return response()->json([
            'users' => DB::table('users')->count(),
            'leagues' => ['total' => DB::table('leagues')->count(), 'running' => DB::table('leagues')->where('status', 'running')->count()],
            'live_matches' => DB::table('matches')->where('status', 'live')->count(),
            'active_today' => DB::table('user_activity')->where('day', $today)->count(),
            'weeks' => Activity::weeks(),
            // Whether a deploy now is safe [X33]: Render runs the old and new versions side by side for about a minute,
            // so nothing should be live or about to kick off (30 minutes), and the next kick-off says how long it stays so.
            'deploy' => [
                'busy' => MatchesLive::busy(30),
                'next_kickoff' => ($next = DB::table('fixtures')->whereIn('status', ['scheduled', 'locked'])->where('is_bye', false)->whereNotNull('home_id')
                    ->whereNotNull('away_id')->where('scheduled_at', '>', GameClock::now())->min('scheduled_at'))
                    ? Carbon::parse($next, 'UTC')->toIso8601ZuluString() : null,
            ],
        ]);
    }

    /**
     * [Sprint 21 E7.3] The accounts, the admins apart from the coaches, searched by the account's number (five
     * digits) or by the name, the username or the email.
     */
    public function users(Request $request): JsonResponse
    {
        $q = trim((string) ($request->validate(['q' => ['nullable', 'string', 'max:80']])['q'] ?? ''));
        $rows = DB::table('users')->leftJoin('user_activity', 'user_activity.user_id', '=', 'users.id')
            ->when($q !== '', fn ($query) => preg_match('/^\d{5}$/', $q) ? $query->where('users.account_no', (int) $q)
                : $query->where(fn ($w) => $w->whereLike('users.name', "%{$q}%")->orWhereLike('users.username', '%'.strtolower($q).'%')->orWhereLike('users.email', '%'.strtolower($q).'%')))
            ->groupBy('users.id', 'users.account_no', 'users.name', 'users.username', 'users.email', 'users.role', 'users.created_at', 'users.account_verified_at', 'users.suspended_at', 'users.suspended_reason')
            ->orderByDesc('users.id')->limit(300)
            ->get(['users.id', 'users.account_no', 'users.name', 'users.username', 'users.email', 'users.role', 'users.created_at', 'users.account_verified_at', 'users.suspended_at', 'users.suspended_reason',
                DB::raw('max(user_activity.day) as last_day'), DB::raw('coalesce(sum(user_activity.matches_watched), 0) as live')]);
        $row = fn ($u) => ['id' => $u->id, 'account_no' => $u->account_no, 'name' => $u->name, 'username' => $u->username, 'email' => $u->email, 'role' => $u->role,
            'official' => Username::official($u->username), 'verified' => $u->account_verified_at !== null,
            'suspended' => $u->suspended_at ? ['at' => Carbon::parse($u->suspended_at, 'UTC')->toIso8601ZuluString(), 'reason' => $u->suspended_reason] : null,
            'joined' => Carbon::parse($u->created_at, 'UTC')->toIso8601ZuluString(), 'last_day' => $u->last_day, 'matches_watched' => (int) $u->live];

        return response()->json(['admins' => $rows->where('role', 'admin')->map($row)->values(), 'users' => $rows->where('role', '!=', 'admin')->map($row)->values()]);
    }

    /** [Sprint 21 E7.3] Suspend a coach's account (not an admin's), with the reason he will read; logged. */
    public function suspend(Request $request, User $user): JsonResponse
    {
        abort_if($user->isAdmin(), 409, 'لا يُعلَّق حساب مدير.');
        $reason = trim((string) $request->validate(['reason' => ['required', 'string', 'min:3', 'max:300']])['reason']);
        $user->forceFill(['suspended_at' => GameClock::now(), 'suspended_reason' => $reason])->save();
        Sessions::forget($user->id);
        $user->tokens()->delete();
        $this->log($request, 'suspend', $user, $reason);

        return response()->json(['ok' => true]);
    }

    public function unsuspend(Request $request, User $user): JsonResponse
    {
        $user->forceFill(['suspended_at' => null, 'suspended_reason' => null])->save();
        $this->log($request, 'unsuspend', $user);

        return response()->json(['ok' => true]);
    }

    /** [Sprint 21 E7.3] Delete a coach's account for good: the admin types its number to confirm; logged. */
    public function deleteUser(Request $request, User $user): JsonResponse
    {
        abort_if($user->isAdmin(), 409, 'لا يُحذف حساب مدير من اللوحة.');
        $confirm = (int) $request->validate(['confirm' => ['required', 'integer']])['confirm'];
        abort_unless($confirm === (int) $user->account_no, 422, 'اكتب رقم الحساب نفسه لتأكيد الحذف.');
        $this->log($request, 'delete', $user, "{$user->name} @{$user->username}");
        AccountDeletion::delete($user);

        return response()->json(['ok' => true]);
    }

    /** What the admins did to accounts, newest first. */
    private function log(Request $request, string $action, User $user, ?string $details = null): void
    {
        DB::table('admin_log')->insert(['admin_id' => $request->user()->id, 'action' => $action, 'target_user_id' => $user->id,
            'details' => $details ? mb_substr($details, 0, 300) : null, 'created_at' => GameClock::now()]);
    }

    /** [Sprint 21 E7.5] The activity day by day (Cairo), the new accounts, and what the admins did. */
    public function activity(Request $request): JsonResponse
    {
        $days = (int) ($request->validate(['days' => ['nullable', 'integer', 'min:7', 'max:90']])['days'] ?? 14);
        $today = GameClock::now()->setTimezone('Africa/Cairo')->startOfDay();
        $from = $today->copy()->subDays($days - 1)->toDateString();
        $rows = DB::table('user_activity')->where('day', '>=', $from)->groupBy('day')
            ->get(['day', DB::raw('count(*) as active'), DB::raw('sum(logins) as logins'), DB::raw('sum(matches_watched) as watched'), DB::raw('sum(orders) as orders')])->keyBy('day');
        $joined = DB::table('users')->where('created_at', '>=', $today->copy()->subDays($days - 1)->setTimezone('UTC'))->pluck('created_at')
            ->countBy(fn ($at) => Carbon::parse($at, 'UTC')->setTimezone('Africa/Cairo')->toDateString());
        $out = [];
        for ($d = 0; $d < $days; $d++) {
            $day = $today->copy()->subDays($d)->toDateString();
            $r = $rows[$day] ?? null;
            $out[] = ['day' => $day, 'active' => (int) ($r->active ?? 0), 'logins' => (int) ($r->logins ?? 0), 'watched' => (int) ($r->watched ?? 0), 'orders' => (int) ($r->orders ?? 0), 'joined' => (int) ($joined[$day] ?? 0)];
        }
        $names = DB::table('users')->pluck('name', 'id');
        $log = DB::table('admin_log')->orderByDesc('id')->limit(50)->get()
            ->map(fn ($l) => ['action' => $l->action, 'admin' => $names[$l->admin_id] ?? null, 'target' => $l->target_user_id ? ($names[$l->target_user_id] ?? null) : null,
                'details' => $l->details, 'at' => Carbon::parse($l->created_at, 'UTC')->toIso8601ZuluString()]);

        return response()->json(['days' => $out, 'log' => $log]);
    }

    public function leagues(): JsonResponse
    {
        $rows = DB::table('leagues')->leftJoin('users', 'users.id', '=', 'leagues.owner_id')->orderByDesc('leagues.id')->limit(200)
            ->get(['leagues.id', 'leagues.name', 'leagues.status', 'leagues.team_count', 'leagues.is_dev', 'users.name as owner', 'users.account_no as owner_no']);

        return response()->json(['leagues' => $rows->map(fn ($l) => ['id' => $l->id, 'name' => $l->name, 'status' => $l->status, 'teams' => (int) $l->team_count,
            // [Sprint 21 E7.6] The creator's account number beside his name.
            'dev' => (bool) $l->is_dev, 'owner' => $l->owner, 'owner_no' => $l->owner_no,
            'coaches' => DB::table('clubs')->where('league_id', $l->id)->whereNotNull('user_id')->count(),
            'season' => (int) DB::table('seasons')->where('league_id', $l->id)->max('number')])]);
    }

    /** The email settings and a test email to the given address, with the exact error and its fix [X8]. */
    public function mailTest(Request $request): JsonResponse
    {
        $to = (string) $request->validate(['to' => ['required', 'email']])['to'];
        $setup = Mailer::setup();
        try {
            Mail::raw('رسالة تجربة من لعبة المدرب الأسطورة: البريد يعمل.', fn ($m) => $m->to($to)->subject('تجربة البريد في لعبة المدرب الأسطورة'));
        } catch (\Throwable $e) {
            return response()->json($setup + ['sent' => false, 'error' => substr($e->getMessage(), 0, 600), 'fix' => Mailer::explain($e->getMessage())]);
        }

        return response()->json($setup + ['sent' => Mailer::live(), 'error' => null, 'fix' => Mailer::live() ? null : $setup['problems'][0] ?? null]);
    }

    /** [UP13] The long holidays the developers decide, the waiting ones first. */
    public function vacations(): JsonResponse
    {
        $rows = DB::table('account_vacations')->join('users', 'users.id', '=', 'account_vacations.user_id')->leftJoin('users as deciders', 'deciders.id', '=', 'account_vacations.decided_by')
            ->where('account_vacations.status', '!=', 'auto')
            ->orderByRaw("case when account_vacations.status = 'pending' then 0 else 1 end")->orderByDesc('account_vacations.id')->limit(100)
            ->get(['account_vacations.*', 'users.name', 'users.username', 'users.account_no', 'deciders.name as decider']);
        $at = fn ($v) => $v ? Carbon::parse($v, 'UTC')->toIso8601ZuluString() : null;

        // [Sprint 21 E7.4] Who, for how long, from when to when, why, and who decided.
        return response()->json(['vacations' => $rows->map(fn ($r) => ['id' => $r->id, 'user' => ['id' => $r->user_id, 'name' => $r->name, 'username' => $r->username, 'account_no' => $r->account_no],
            'days' => (int) $r->days, 'reason' => $r->reason, 'status' => $r->status, 'asked_at' => $at($r->created_at),
            'starts_at' => $at($r->starts_at), 'ends_at' => $at($r->ends_at), 'decided_at' => $at($r->decided_at), 'decided_by' => $r->decider])]);
    }

    public function decideVacation(Request $request, int $id): JsonResponse
    {
        $approve = (bool) $request->validate(['approve' => ['required', 'boolean']])['approve'];

        return response()->json(['vacation' => AccountHolidays::decide($id, $request->user(), $approve)]);
    }

    /** [UP6] A code that verifies this account, for the developer to send to the coach on WhatsApp. */
    public function verificationCode(Request $request, User $user): JsonResponse
    {
        return response()->json(['code' => AccountVerification::issue($user, $request->user()), 'username' => $user->username, 'id' => $user->id,
            'days' => (int) config('game.account.verify_code_days')]);
    }

    /** Gives a developer's account one of the reserved names (Owner-Sizar, Owner-Sliman) and its badge [X11]. */
    public function official(Request $request, User $user): JsonResponse
    {
        $name = (string) $request->validate(['name' => ['required', 'string', Rule::in(config('game.account.official_usernames'))]])['name'];
        abort_if(Username::taken($name, $user->id), 409, 'هذا الاسم الرسمي لحساب آخر.');
        $user->forceFill(['username' => strtolower($name)])->save();

        return response()->json(['user' => $user->toAccount()]);
    }

    /** A message from the developers to every account, signed with the official badge [X11]. Only from an official account. */
    public function announce(Request $request): JsonResponse
    {
        $from = $request->user();
        abort_unless(Username::official($from->username), 403, 'الإعلانات من حسابات المطورين الرسمية فقط (Owner-Sizar أو Owner-Sliman).');
        $data = $request->validate(['title' => ['required', 'string', 'max:120'], 'body' => ['required', 'string', 'max:2000']]);
        $payload = ['title' => $data['title'], 'body' => $data['body'], 'from' => $from->name, 'username' => $this->officialName($from->username)];
        $sent = 0;
        foreach (User::query()->pluck('id') as $id) {
            Inbox::send($id, 'announcement', $payload);
            $sent++;
        }
        // [Sprint 21 E7.2] Kept as sent: the text, who sent it and when.
        DB::table('announcements')->insert(['user_id' => $from->id, 'title' => $data['title'], 'body' => $data['body'], 'sent' => $sent, 'created_at' => GameClock::now()]);

        return response()->json(['sent' => $sent], 201);
    }

    /** [Sprint 21 E7.2] The announcements sent, newest first, each whole with its sender and time. */
    public function announcements(): JsonResponse
    {
        $rows = DB::table('announcements')->leftJoin('users', 'users.id', '=', 'announcements.user_id')->orderByDesc('announcements.id')->limit(100)
            ->get(['announcements.*', 'users.name', 'users.username']);

        return response()->json(['announcements' => $rows->map(fn ($a) => ['id' => $a->id, 'title' => $a->title, 'body' => $a->body, 'sent' => (int) $a->sent,
            'sender' => $a->name ? ['name' => $a->name, 'username' => $this->officialName((string) $a->username), 'official' => Username::official($a->username)] : null,
            'at' => Carbon::parse($a->created_at, 'UTC')->toIso8601ZuluString()])]);
    }

    /** [Sprint 21 E7.7] The conversations with the coaches; one coach's thread; a developer writes to a coach. */
    public function conversations(): JsonResponse
    {
        return response()->json(['conversations' => Conversations::inbox()]);
    }

    public function conversation(User $user): JsonResponse
    {
        Conversations::markRead($user->id, true);

        return response()->json(['user' => ['id' => $user->id, 'name' => $user->name, 'username' => $user->username, 'account_no' => $user->account_no], 'messages' => Conversations::thread($user->id)]);
    }

    public function writeTo(Request $request, User $user): JsonResponse
    {
        $body = trim((string) $request->validate(['body' => ['required', 'string', 'min:1', 'max:'.Conversations::MAX]])['body']);
        Conversations::fromTeam($request->user(), $user, $body);

        return $this->conversation($user);
    }

    /** owner-sizar → Owner-Sizar, as written in the settings. */
    private function officialName(string $username): string
    {
        foreach (config('game.account.official_usernames') as $name) {
            if (strtolower($name) === $username) {
                return $name;
            }
        }

        return $username;
    }

    /** The backups on this machine (newest first), and making one now. */
    public function backups(): JsonResponse
    {
        $root = base_path('database/backups');
        $dirs = File::isDirectory($root) ? collect(File::directories($root))->sort()->reverse()->values() : collect();

        return response()->json(['backups' => $dirs->take(30)->map(fn ($d) => ['name' => basename($d),
            'bytes' => collect(File::files($d))->sum(fn ($f) => $f->getSize())])->all()]);
    }

    public function backupNow(): JsonResponse
    {
        Artisan::call('db:backup');

        return $this->backups();
    }

    /**
     * One backup's game database to keep off the server [X33]: on Render the backups live only until the next
     * restart, so the admin downloads the copy made before a deploy (start.sh) to have it on his own machine.
     */
    public function downloadBackup(string $name): BinaryFileResponse
    {
        // [X43] On Supabase a backup is the game's rows in one file (db:backup); on SQLite, its database file.
        $rows = base_path('database/backups/'.basename($name).'/legends.jsonl.gz');
        if (is_file($rows)) {
            return response()->download($rows, "legends-$name.jsonl.gz", ['Content-Type' => 'application/gzip']);
        }
        $file = base_path('database/backups/'.basename($name).'/'.basename((string) config('database.connections.sqlite.database')));
        abort_unless(is_file($file), 404, 'هذه النسخة غير موجودة.');

        return response()->download($file, "legends-$name.sqlite", ['Content-Type' => 'application/vnd.sqlite3']);
    }

    /** The commentary templates: how many lines each moment has, and its lines. */
    public function commentary(): JsonResponse
    {
        $table = Commentary::table();

        return response()->json(['keys' => collect($table)->map(fn ($lines, $key) => ['key' => $key, 'count' => count($lines), 'lines' => array_values($lines)])->values()]);
    }

    /** The alliance tournaments waiting for the developers, and the latest decided [X27]. */
    public function alliances(): JsonResponse
    {
        $rows = DB::table('alliance_tournaments')->join('leagues', 'leagues.id', '=', 'alliance_tournaments.league_id')
            ->orderByRaw("alliance_tournaments.status = 'pending' desc")->orderByDesc('alliance_tournaments.id')->limit(30)
            ->get(['alliance_tournaments.*', 'leagues.name as league']);
        $captains = DB::table('users')->whereIn('id', $rows->pluck('captain_a')->merge($rows->pluck('captain_b')))->pluck('username', 'id');

        return response()->json(['tournaments' => $rows->map(fn ($t) => [
            'id' => $t->id, 'league_id' => $t->league_id, 'league' => $t->league, 'name' => $t->name, 'status' => $t->status, 'size' => (int) $t->size,
            'captains' => [$captains[$t->captain_a] ?? null, $captains[$t->captain_b] ?? null],
            'first_round_at' => Carbon::parse($t->first_round_at, 'UTC')->toIso8601ZuluString(), 'review_note' => $t->review_note,
        ])->values()]);
    }

    public function reviewAlliance(Request $request, int $id): JsonResponse
    {
        $data = $request->validate(['approve' => ['required', 'boolean'], 'note' => ['nullable', 'string', 'max:200']]);
        Alliance::review($id, $request->user(), (bool) $data['approve'], $data['note'] ?? null);

        return $this->alliances();
    }
}
