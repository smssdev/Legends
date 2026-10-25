<?php

namespace App\Http\Controllers\Api;

use App\Admin\TwoFactor;
use App\Auth\Username;
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

        return response()->json(['enabled' => (bool) $request->user()->two_factor_enabled_at, 'passed' => TwoFactor::passed()]);
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
        ]);
    }

    public function users(): JsonResponse
    {
        $rows = DB::table('users')->leftJoin('user_activity', 'user_activity.user_id', '=', 'users.id')
            ->groupBy('users.id', 'users.name', 'users.email', 'users.role', 'users.created_at')
            ->orderByDesc('users.id')->limit(200)
            ->get(['users.id', 'users.name', 'users.email', 'users.role', 'users.created_at', DB::raw('max(user_activity.day) as last_day'),
                DB::raw('coalesce(sum(user_activity.matches_watched), 0) as live')]);

        return response()->json(['users' => $rows->map(fn ($u) => ['id' => $u->id, 'name' => $u->name, 'email' => $u->email, 'role' => $u->role,
            'joined' => Carbon::parse($u->created_at, 'UTC')->toIso8601ZuluString(), 'last_day' => $u->last_day, 'matches_watched' => (int) $u->live])]);
    }

    public function leagues(): JsonResponse
    {
        $rows = DB::table('leagues')->leftJoin('users', 'users.id', '=', 'leagues.owner_id')->orderByDesc('leagues.id')->limit(200)
            ->get(['leagues.id', 'leagues.name', 'leagues.status', 'leagues.team_count', 'leagues.is_dev', 'users.name as owner']);

        return response()->json(['leagues' => $rows->map(fn ($l) => ['id' => $l->id, 'name' => $l->name, 'status' => $l->status, 'teams' => (int) $l->team_count,
            'dev' => (bool) $l->is_dev, 'owner' => $l->owner,
            'coaches' => DB::table('clubs')->where('league_id', $l->id)->whereNotNull('user_id')->count(),
            'season' => (int) DB::table('seasons')->where('league_id', $l->id)->max('number')])]);
    }

    /** The email settings and a test email to the given address, with the exact error and its fix [X8]. */
    public function mailTest(Request $request): JsonResponse
    {
        $to = (string) $request->validate(['to' => ['required', 'email']])['to'];
        $setup = Mailer::setup();
        try {
            Mail::raw('رسالة تجربة من الأساطير: البريد يعمل.', fn ($m) => $m->to($to)->subject('تجربة البريد في الأساطير'));
        } catch (\Throwable $e) {
            return response()->json($setup + ['sent' => false, 'error' => substr($e->getMessage(), 0, 600), 'fix' => Mailer::explain($e->getMessage())]);
        }

        return response()->json($setup + ['sent' => Mailer::live(), 'error' => null, 'fix' => Mailer::live() ? null : $setup['problems'][0] ?? null]);
    }

    /** Gives a developer's account one of the reserved names (Owner-Hamza, Owner-Soliman) and its badge [X11]. */
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
        abort_unless(Username::official($from->username), 403, 'الإعلانات من حسابات المطورين الرسمية فقط (Owner-Hamza أو Owner-Soliman).');
        $data = $request->validate(['title' => ['required', 'string', 'max:120'], 'body' => ['required', 'string', 'max:2000']]);
        $payload = ['title' => $data['title'], 'body' => $data['body'], 'from' => $from->name, 'username' => $this->officialName($from->username)];
        $sent = 0;
        foreach (User::query()->pluck('id') as $id) {
            Inbox::send($id, 'announcement', $payload);
            $sent++;
        }

        return response()->json(['sent' => $sent], 201);
    }

    /** owner-hamza → Owner-Hamza, as written in the settings. */
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
