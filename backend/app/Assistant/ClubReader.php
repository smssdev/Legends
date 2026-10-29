<?php

namespace App\Assistant;

use App\Http\Controllers\Api\ClubBoardController;
use App\Http\Controllers\Api\LeagueController;
use App\Http\Controllers\Api\SpecialistController;
use App\Http\Controllers\Api\StadiumController;
use App\Http\Controllers\Api\TeamController;
use App\Http\Controllers\Api\TrainingController;
use App\Models\Club;
use App\Models\League;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * What the Assistant Coach reads of the coach's own club [Sprint 22 B3]: read only, the asking coach's club alone. Each
 * part is the same answer the coach's own screen gets (the same controller, as him), so the assistant can know
 * nothing his screen does not show: never an opponent's private tactics, never another club's secrets. The accounts'
 * emails, pictures and links come off, and the long lists are cut, before anything leaves the server.
 */
class ClubReader
{
    public const PARTS = ['summary', 'squad', 'tactics', 'next_match', 'last_match', 'training', 'finance', 'standings', 'stadium', 'specialists'];

    /** What each part holds, for the AI to choose from. */
    public const ABOUT = 'summary: money, coins, next match, position, objective, timers and what waits; squad: every player with position, '
        .'strength, value, fitness, morale, injuries and role (starter, bench, reserve), and the lines\' strength; tactics: the coach\'s '
        .'own saved tactics and the tips; next_match: the next opponent as everyone may see it, the referee and the lineups after the lock; '
        .'last_match: the report of the coach\'s last finished match; training: who trains and their progress; finance: balance, wages, '
        .'income and costs of the season; standings: the league table; stadium: the stadium\'s sections and building; specialists: the staff hired and on offer.';

    private const DROP = ['email', 'avatar_url', 'crest_url', 'logo', 'url', 'image', 'cells', 'custom_formations', 'coach', 'username', 'user'];

    public function __construct(private User $user, private League $league, private Club $club) {}

    /** The coach's club in that league, or null when he has none there. */
    public static function for(User $user, ?int $leagueId): ?self
    {
        $league = $leagueId ? League::find($leagueId) : null;
        $club = $league ? Club::where('league_id', $league->id)->where('user_id', $user->id)->first() : null;

        return $club ? new self($user, $league, $club) : null;
    }

    public function clubName(): string
    {
        return (string) $this->club->name;
    }

    public function read(string $part): array
    {
        if (! in_array($part, self::PARTS, true)) {
            return ['error' => 'unknown part'];
        }
        try {
            $data = match ($part) {
                'summary' => $this->call(ClubBoardController::class, 'summary'),
                'squad' => $this->squad(),
                'tactics' => $this->call(TeamController::class, 'tactics'),
                'next_match' => $this->call(TeamController::class, 'nextMatch'),
                'last_match' => $this->lastMatch(),
                'training' => $this->call(TrainingController::class, 'show'),
                'finance' => $this->call(TeamController::class, 'finance'),
                'standings' => $this->call(LeagueController::class, 'standings'),
                'stadium' => $this->call(StadiumController::class, 'show'),
                'specialists' => $this->call(SpecialistController::class, 'show'),
            };
        } catch (HttpException $e) {
            return ['error' => $e->getMessage()];
        }

        return self::clean($data);
    }

    /** The squad, each player in a few numbers (not his every attribute). */
    private function squad(): array
    {
        $team = $this->call(TeamController::class, 'show');
        $keep = ['id', 'name', 'position', 'positions', 'age', 'overall', 'potential', 'value', 'fitness', 'injured_matches',
            'suspended_matches', 'role', 'nationality', 'on_sale', 'training', 'progress_bp'];
        $team['players'] = array_map(fn ($p) => array_intersect_key($p, array_flip($keep)), $team['players'] ?? []);
        unset($team['lineup'], $team['takers']);

        return $team;
    }

    /** The coach's last finished match: its result, reasons and ratings (his side), read without marking it seen. */
    private function lastMatch(): array
    {
        $row = DB::table('match_reports')->join('matches', 'matches.id', '=', 'match_reports.match_id')
            ->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')
            ->where('match_reports.club_id', $this->club->id)->orderByDesc('match_reports.match_id')
            ->first(['match_reports.report', 'fixtures.home_id', 'fixtures.away_id', 'fixtures.competition', 'fixtures.round']);
        if (! $row) {
            return ['none' => 'no finished match yet'];
        }
        $side = $row->home_id === $this->club->id ? 'home' : 'away';
        $other = DB::table('clubs')->where('id', $side === 'home' ? $row->away_id : $row->home_id)->value('name');
        $r = json_decode($row->report, true);
        $r['ratings'] = ['mine' => $r['ratings'][$side] ?? [], 'theirs_top3' => array_slice($r['ratings'][$side === 'home' ? 'away' : 'home'] ?? [], 0, 3)];
        unset($r['timeline'], $r['momentum']);

        return ['you_were' => $side, 'opponent' => $other, 'competition' => $row->competition, 'round' => (int) $row->round] + $r;
    }

    /** One of the coach's own screens' answers, as him. */
    private function call(string $controller, string $method): array
    {
        $request = Request::create('/', 'GET');
        $request->setUserResolver(fn () => $this->user);

        return app($controller)->{$method}($request, $this->league)->getData(true);
    }

    /** No account's email, picture or link, no very long text, and at most 40 of anything. */
    public static function clean(mixed $v, int $depth = 0): mixed
    {
        if (is_string($v)) {
            return mb_strlen($v) > 400 ? mb_substr($v, 0, 400).'…' : $v;
        }
        if (! is_array($v)) {
            return $v;
        }
        if ($depth > 6) {
            return '…';
        }
        $out = [];
        foreach (array_slice($v, 0, 40, true) as $k => $x) {
            if (is_string($k) && (in_array($k, self::DROP, true) || str_ends_with($k, '_url'))) {
                continue;
            }
            $out[$k] = self::clean($x, $depth + 1);
        }

        return $out;
    }
}
