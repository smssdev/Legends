<?php

namespace App\Http\Controllers\Api;

use App\Admin\TwoFactor;
use App\Http\Controllers\Controller;
use App\Simulator\Commentary;
use App\Support\Activity;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

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
}
