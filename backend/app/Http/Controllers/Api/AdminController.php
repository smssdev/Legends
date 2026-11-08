<?php

namespace App\Http\Controllers\Api;

use App\Admin\Announcements;
use App\Admin\Conversations;
use App\Admin\JunkContent;
use App\Auth\AccountDeletion;
use App\Auth\AccountHolidays;
use App\Auth\AccountVerification;
use App\Auth\Sessions;
use App\Auth\Username;
use App\Chat\ChatGroups;
use App\Chat\Moderation;
use App\Console\Commands\MatchesLive;
use App\Http\Controllers\Controller;
use App\League\Alliance;
use App\Messages\Inbox;
use App\Models\User;
use App\Rules\NotJunk;
use App\Simulator\Commentary;
use App\Support\Activity;
use App\Support\Avatar;
use App\Support\GameClock;
use App\Support\GameSettings;
use App\Support\Mailer;
use App\Wallet\Wallet;
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

    /**
     * [Sprint 39 A1] What this admin may open (null: everything). Signed in with the password is enough: the two-step
     * code is gone (the owner's request, 2026-11-02).
     */
    public function access(Request $request): JsonResponse
    {
        $this->adminOnly($request);

        return response()->json(['scope' => $request->user()->admin_scope,
            'sections' => $request->user()->admin_scope ? config('game.admin.scopes')[$request->user()->admin_scope] : null]);
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
        $data = $request->validate(['q' => ['nullable', 'string', 'max:80'], 'page' => ['nullable', 'integer', 'min:1', 'max:10000']]);
        $q = trim((string) ($data['q'] ?? ''));
        // [Sprint 21 close] The coaches a page at a time (the admins are few and come whole), newest first.
        $page = (int) ($data['page'] ?? 1);
        $per = (int) config('game.admin.users_per_page');
        $query = fn (bool $admins) => DB::table('users')->leftJoin('user_activity', 'user_activity.user_id', '=', 'users.id')
            ->where('users.role', $admins ? '=' : '!=', 'admin')
            ->when($q !== '', fn ($query) => preg_match('/^\d{5}$/', $q) ? $query->where('users.account_no', (int) $q)
                : $query->where(fn ($w) => $w->whereLike('users.name', "%{$q}%")->orWhereLike('users.username', '%'.strtolower($q).'%')->orWhereLike('users.email', '%'.strtolower($q).'%')))
            ->groupBy('users.id', 'users.account_no', 'users.name', 'users.username', 'users.email', 'users.role', 'users.admin_scope', 'users.created_at', 'users.account_verified_at', 'users.suspended_at', 'users.suspended_reason')
            ->orderByDesc('users.id')
            ->select(['users.id', 'users.account_no', 'users.name', 'users.username', 'users.email', 'users.role', 'users.admin_scope', 'users.created_at', 'users.account_verified_at', 'users.suspended_at', 'users.suspended_reason',
                DB::raw('max(user_activity.day) as last_day'), DB::raw('coalesce(sum(user_activity.matches_watched), 0) as live')]);
        $row = fn ($u) => ['id' => $u->id, 'account_no' => $u->account_no, 'name' => $u->name, 'username' => $u->username, 'email' => $u->email, 'role' => $u->role, 'admin_scope' => $u->admin_scope,
            'official' => Username::official($u->username), 'verified' => $u->account_verified_at !== null,
            'suspended' => $u->suspended_at ? ['at' => Carbon::parse($u->suspended_at, 'UTC')->toIso8601ZuluString(), 'reason' => $u->suspended_reason] : null,
            'joined' => Carbon::parse($u->created_at, 'UTC')->toIso8601ZuluString(), 'last_day' => $u->last_day, 'matches_watched' => (int) $u->live];
        $users = $query(false)->offset(($page - 1) * $per)->limit($per + 1)->get();

        return response()->json(['admins' => $page === 1 ? $query(true)->limit(50)->get()->map($row)->values() : [],
            'users' => $users->take($per)->map($row)->values(), 'page' => $page, 'has_more' => $users->count() > $per]);
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
        $this->fullAdmin($request);
        abort_if($user->isAdmin(), 409, 'لا يُحذف حساب مدير من اللوحة.');
        $confirm = (int) $request->validate(['confirm' => ['required', 'integer']])['confirm'];
        abort_unless($confirm === (int) $user->account_no, 422, 'اكتب رقم الحساب نفسه لتأكيد الحذف.');
        $this->log($request, 'delete', $user, "{$user->name} @{$user->username}");
        AccountDeletion::delete($user);

        return response()->json(['ok' => true]);
    }

    /** What the admins did to accounts, newest first. */
    /** [Sprint 30 Q11] Every sensitive admin action, with the reason and the address it came from. */
    private function log(Request $request, string $action, ?User $user, ?string $details = null): void
    {
        DB::table('admin_log')->insert(['admin_id' => $request->user()->id, 'action' => $action, 'target_user_id' => $user?->id,
            'details' => $details ? mb_substr($details, 0, 300) : null, 'ip' => $request->ip(), 'created_at' => GameClock::now()]);
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
        $log = DB::table('admin_log')->orderByDesc('id')->limit(50)->get();
        // Only the names the log needs, not every account's.
        $names = DB::table('users')->whereIn('id', $log->pluck('admin_id')->merge($log->pluck('target_user_id'))->filter()->unique())->pluck('name', 'id');
        $log = $log
            ->map(fn ($l) => ['action' => $l->action, 'admin' => $names[$l->admin_id] ?? null, 'target' => $l->target_user_id ? ($names[$l->target_user_id] ?? null) : null,
                'details' => $l->details, 'at' => Carbon::parse($l->created_at, 'UTC')->toIso8601ZuluString()]);

        return response()->json(['days' => $out, 'log' => $log]);
    }

    public function leagues(): JsonResponse
    {
        $rows = DB::table('leagues')->leftJoin('users', 'users.id', '=', 'leagues.owner_id')->orderByDesc('leagues.id')->limit(200)
            ->get(['leagues.id', 'leagues.name', 'leagues.status', 'leagues.team_count', 'leagues.is_dev', 'users.name as owner', 'users.account_no as owner_no']);
        // The coaches and the season of every league in two queries, not two per league.
        $coaches = DB::table('clubs')->whereIn('league_id', $rows->pluck('id'))->whereNotNull('user_id')->groupBy('league_id')->select('league_id', DB::raw('count(*) as n'))->pluck('n', 'league_id');
        $seasons = DB::table('seasons')->whereIn('league_id', $rows->pluck('id'))->groupBy('league_id')->select('league_id', DB::raw('max(number) as n'))->pluck('n', 'league_id');

        return response()->json(['leagues' => $rows->map(fn ($l) => ['id' => $l->id, 'name' => $l->name, 'status' => $l->status, 'teams' => (int) $l->team_count,
            // [Sprint 21 E7.6] The creator's account number beside his name.
            'dev' => (bool) $l->is_dev, 'owner' => $l->owner, 'owner_no' => $l->owner_no,
            'coaches' => (int) ($coaches[$l->id] ?? 0), 'season' => (int) ($seasons[$l->id] ?? 0)])]);
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
        $this->log($request, 'verify_code', $user);

        return response()->json(['code' => AccountVerification::issue($user, $request->user()), 'username' => $user->username, 'id' => $user->id,
            'days' => (int) config('game.account.verify_code_days')]);
    }

    /** Gives a developer's account one of the reserved names (Owner-Sizar, Owner-Sliman) and its badge [X11]. */
    public function official(Request $request, User $user): JsonResponse
    {
        $this->fullAdmin($request);
        $name = (string) $request->validate(['name' => ['required', 'string', Rule::in(config('game.account.official_usernames'))]])['name'];
        abort_if(Username::taken($name, $user->id), 409, 'هذا الاسم الرسمي لحساب آخر.');
        $user->forceFill(['username' => strtolower($name)])->save();
        $this->log($request, 'official', $user, $name);

        return response()->json(['user' => $user->toAccount()]);
    }

    /** A message from the developers to every account, signed with the official badge [X11]. Only from an official account. */
    public function announce(Request $request): JsonResponse
    {
        $from = $request->user();
        abort_unless(Username::official($from->username), 403, 'الإعلانات من حسابات المطورين الرسمية فقط (Owner-Sizar أو Owner-Sliman).');
        // [X54] A card: an optional wide picture, and an optional button to a page of the game (/...) or a site (https).
        $data = $request->validate(['title' => ['required', 'string', 'max:120', new NotJunk], 'body' => ['required', 'string', 'max:2000', new NotJunk],
            'image' => ['nullable', 'image', 'mimes:jpeg,png,webp,gif', 'max:'.config('game.announcements.image_max_kb')],
            'cta_label' => ['nullable', 'required_with:cta_url', 'string', 'max:40'],
            'cta_url' => ['nullable', 'required_with:cta_label', 'string', 'max:300', 'regex:#^(https?://[^\s]+|/[A-Za-z0-9/_\-?=&%.]*)$#']]);
        $jpeg = null;
        if ($request->hasFile('image')) {
            $jpeg = Avatar::wide((string) file_get_contents($request->file('image')->getRealPath()), (int) config('game.announcements.image_width'), (int) config('game.announcements.image_max_height'));
            abort_unless($jpeg !== null, 422, 'تعذرت قراءة الصورة، جرّب صورة أخرى.');
        }
        $now = GameClock::now();
        // [Sprint 21 E7.2] Kept as sent: the text, who sent it and when.
        $id = DB::table('announcements')->insertGetId(['user_id' => $from->id, 'title' => $data['title'], 'body' => $data['body'], 'sent' => 0,
            'cta_label' => $data['cta_label'] ?? null, 'cta_url' => $data['cta_url'] ?? null, 'has_image' => $jpeg !== null, 'created_at' => $now]);
        if ($jpeg !== null) {
            DB::table('announcement_images')->insert(['announcement_id' => $id, 'image' => $jpeg, 'created_at' => $now]);
        }
        $payload = ['title' => $data['title'], 'body' => $data['body'], 'from' => $from->name, 'username' => $this->officialName($from->username), 'announcement_id' => $id];
        $sent = 0;
        foreach (User::query()->pluck('id') as $uid) {
            Inbox::send($uid, 'announcement', $payload);
            $sent++;
        }
        DB::table('announcements')->where('id', $id)->update(['sent' => $sent]);

        return response()->json(['sent' => $sent, 'announcement' => Announcements::card(DB::table('announcements')->leftJoin('users', 'users.id', '=', 'announcements.user_id')
            ->where('announcements.id', $id)->first(['announcements.*', 'users.name', 'users.username']))], 201);
    }

    /** [Sprint 21 E7.2] The announcements sent, newest first, each whole with its sender and time. */
    public function announcements(): JsonResponse
    {
        return response()->json(['announcements' => Announcements::list(100)]);
    }

    /**
     * [X54, the owner's request 2026-10-29] Coins to any account, by its five-digit number: an amount, the reason the
     * coach reads, logged; once per idempotency key, so a double tap gives once.
     */
    /** [X65] The chat groups' settings: how many days their messages are kept (0: always), whether media may be sent, and their size. */
    public function chat(): JsonResponse
    {
        return response()->json([
            'retention_days' => (int) GameSettings::get('chat.retention_days'),
            'media' => (bool) GameSettings::get('chat.media'),
            'groups' => DB::table('chat_groups')->count(),
            'messages' => DB::table('chat_group_messages')->count(),
            'media_count' => DB::table('chat_media')->count(),
            'media_kb' => intdiv((int) DB::table('chat_media')->sum('bytes'), 1024),
            'oldest' => ($at = DB::table('chat_group_messages')->min('created_at')) ? Carbon::parse($at, 'UTC')->toIso8601ZuluString() : null,
        ]);
    }

    public function setChat(Request $request): JsonResponse
    {
        $data = $request->validate(['retention_days' => ['required', 'integer', 'between:0,365'], 'media' => ['required', 'boolean']]);
        GameSettings::set('chat.retention_days', $data['retention_days']);
        GameSettings::set('chat.media', $data['media']);

        return $this->chat();
    }

    /** Apply the retention now rather than at the hour. */
    public function pruneChat(): JsonResponse
    {
        return response()->json(['deleted' => ChatGroups::prune()] + $this->chat()->getData(true));
    }

    public function giveCoins(Request $request): JsonResponse
    {
        $data = $request->validate(['account_no' => ['required', 'integer', 'between:10000,99999'], 'amount' => ['required', 'integer', 'min:1', 'max:'.config('game.admin.coins_max')],
            'reason' => ['required', 'string', 'min:3', 'max:200'], 'idempotency_key' => ['required', 'string', 'max:60']]);
        $user = User::where('account_no', $data['account_no'])->first();
        abort_unless($user, 404, 'لا حساب بهذا الرقم.');
        $key = 'admin_gift:'.$data['idempotency_key'];
        $fresh = ! DB::table('wallet_transactions')->where('idempotency_key', $key)->exists();
        $balance = Wallet::post($user->id, 'admin_gift', (int) $data['amount'], $key, 'admin:'.$request->user()->id);
        if ($fresh) {
            $this->log($request, 'coins', $user, "+{$data['amount']} · ".trim($data['reason']));
            Inbox::send($user->id, 'coins_gift', ['coins' => (int) $data['amount'], 'reason' => trim($data['reason']), 'from' => $request->user()->name]);
        }

        return response()->json(['user' => ['id' => $user->id, 'name' => $user->name, 'account_no' => $user->account_no], 'balance' => $balance]);
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

    /** [Sprint 20 S4] The game's own rewarded ads, newest first, with how often each was shown. */
    public function houseAds(): JsonResponse
    {
        return response()->json(['ads' => DB::table('house_ads')->orderByDesc('id')->get()->map(fn ($a) => $this->houseAd($a)),
            'defaults' => count(config('game.ads.house_defaults')), 'enabled' => (bool) config('game.ads.enabled') && config('game.ads.driver') === 'house']);
    }

    public function storeHouseAd(Request $request): JsonResponse
    {
        $data = $request->validate($this->houseAdRules(true));
        $now = GameClock::now();
        $id = DB::table('house_ads')->insertGetId(['user_id' => $request->user()->id, 'title' => $data['title'], 'body' => $data['body'],
            'cta_label' => $data['cta_label'] ?? null, 'cta_url' => $data['cta_url'] ?? null, 'seconds' => $data['seconds'] ?? (int) config('game.ads.house_seconds'),
            'active' => $data['active'] ?? true, 'created_at' => $now, 'updated_at' => $now]);

        return response()->json(['ad' => $this->houseAd(DB::table('house_ads')->find($id))], 201);
    }

    public function updateHouseAd(Request $request, int $id): JsonResponse
    {
        abort_unless(DB::table('house_ads')->where('id', $id)->exists(), 404);
        $data = $request->validate($this->houseAdRules(false));
        DB::table('house_ads')->where('id', $id)->update($data + ['updated_at' => GameClock::now()]);

        return response()->json(['ad' => $this->houseAd(DB::table('house_ads')->find($id))]);
    }

    /** [Sprint 30 G6] The reported group messages, the most reported first. */
    public function reports(): JsonResponse
    {
        return response()->json(['reports' => Moderation::queue()]);
    }

    public function decideReport(Request $request, int $message): JsonResponse
    {
        $action = (string) $request->validate(['action' => ['required', 'in:leave,remove,ban']])['action'];
        $writer = DB::table('chat_group_messages')->where('id', $message)->value('user_id');
        Moderation::decide($message, $request->user(), $action);
        $this->log($request, 'report_'.$action, $writer ? User::find($writer) : null, "message {$message}");

        return $this->reports();
    }

    public function chatUnban(Request $request, User $user): JsonResponse
    {
        $user->forceFill(['chat_banned_at' => null])->save();
        $this->log($request, 'chat_unban', $user);

        return response()->json(['ok' => true]);
    }

    /** [Sprint 30 G6] An admin's scope: support, content or finance (null: full). Only a full admin gives scopes. */
    public function setScope(Request $request, User $user): JsonResponse
    {
        abort_unless($request->user()->admin_scope === null, 403, 'تحديد صلاحيات المشرفين للمدير الكامل فقط.');
        abort_unless($user->isAdmin(), 422, 'الحساب ليس مشرفاً.');
        abort_if($user->id === $request->user()->id, 422, 'لا تغيّر صلاحياتك بنفسك.');
        $scope = $request->validate(['scope' => ['nullable', 'in:'.implode(',', array_keys(config('game.admin.scopes')))]])['scope'] ?? null;
        $user->forceFill(['admin_scope' => $scope])->save();
        $this->log($request, 'scope', $user, $scope ?? 'full');

        return response()->json(['id' => $user->id, 'scope' => $scope]);
    }

    /** [Sprint 30 P3] The test texts players can see: announcements and rewarded ads (removable), and leagues (listed). */
    public function junk(): JsonResponse
    {
        $found = JunkContent::find();
        $row = fn ($r) => ['id' => (int) $r->id, 'title' => (string) ($r->title ?? $r->name)];

        return response()->json(['announcements' => $found['announcements']->map($row)->all(), 'house_ads' => $found['house_ads']->map($row)->all(),
            'leagues' => $found['leagues']->map($row)->all()]);
    }

    public function purgeJunk(Request $request): JsonResponse
    {
        $gone = JunkContent::purge();
        $this->log($request, 'junk', null, "{$gone['announcements']} announcements, {$gone['house_ads']} house ads");

        return response()->json($gone);
    }

    public function deleteHouseAd(int $id): JsonResponse
    {
        DB::table('house_ads')->where('id', $id)->delete();

        return response()->json(['ok' => true]);
    }

    private function houseAdRules(bool $new): array
    {
        $req = $new ? 'required' : 'sometimes';

        // A link opens only on the web (http or https), never a script.
        // [Sprint 30 P3] Never a test's text (NotJunk), as the announcements.
        return ['title' => [$req, 'string', 'min:3', 'max:80', new NotJunk], 'body' => [$req, 'string', 'min:3', 'max:300', new NotJunk],
            'cta_label' => ['sometimes', 'nullable', 'string', 'max:40'], 'cta_url' => ['sometimes', 'nullable', 'url:http,https', 'max:300'],
            'seconds' => ['sometimes', 'integer', 'min:15', 'max:60'], 'active' => ['sometimes', 'boolean']];
    }

    private function houseAd(object $a): array
    {
        return ['id' => $a->id, 'title' => $a->title, 'body' => $a->body, 'cta_label' => $a->cta_label, 'cta_url' => $a->cta_url, 'seconds' => (int) $a->seconds,
            'active' => (bool) $a->active, 'views' => (int) $a->views, 'at' => Carbon::parse($a->created_at, 'UTC')->toIso8601ZuluString()];
    }

    /** owner-sizar → Owner-Sizar, as written in the settings. */
    /**
     * [Sprint 48 A1] What only a full admin does, whatever the scope opens under users/: deleting an account and giving
     * an official name. A support admin still suspends, and issues a verification code for one who gets no email.
     */
    private function fullAdmin(Request $request): void
    {
        abort_unless($request->user()->admin_scope === null, 403, 'هذه العملية للمدير الكامل فقط.');
    }

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

    public function backupNow(Request $request): JsonResponse
    {
        Artisan::call('db:backup');
        $this->log($request, 'backup', null);

        return $this->backups();
    }

    /**
     * One backup's game database to keep off the server [X33]: on Render the backups live only until the next
     * restart, so the admin downloads the copy made before a deploy (start.sh) to have it on his own machine.
     */
    public function downloadBackup(Request $request, string $name): BinaryFileResponse
    {
        $this->log($request, 'download', null, basename($name));
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
