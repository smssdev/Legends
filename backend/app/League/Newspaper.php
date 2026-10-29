<?php

namespace App\League;

use App\Messages\Inbox;
use App\Models\League;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The league's newspaper [UP12, the owner's spec 6]. After each round it writes its own report, made on the server
 * from the round itself (no paid service): the results, the round's big stories (the biggest win, the surprise, the
 * goal feast, the red cards, a hat-trick) and the team of the week from the players' ratings. And the coaches write
 * their own articles, which the league's owner publishes or turns down: one a round each [Sprint 21 E4.5].
 * [Sprint 21 E4.6] «أخبار الدوري»: the round's best matches, its player and its coach (game.press.news, until the
 * owner's own formulas), and the bribes an opponent exposed (the FA's cases of the season).
 */
class Newspaper
{
    private const SHAPE = ['gk' => 1, 'def' => 4, 'mid' => 3, 'att' => 3];

    /** The latest round fully played: its report, or null before the first one. */
    public static function edition(League $league, ?int $round = null): ?array
    {
        $season = DB::table('seasons')->where('league_id', $league->id)->orderByDesc('number')->first();
        if (! $season) {
            return null;
        }
        $played = DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->where('is_bye', false)
            ->select('round', DB::raw("sum(case when status = 'finished' then 0 else 1 end) as open"))->groupBy('round')->get()
            ->filter(fn ($r) => (int) $r->open === 0)->pluck('round')->map(fn ($r) => (int) $r);
        $round ??= $played->max();
        if (! $round || ! $played->contains($round)) {
            return null;
        }
        $fixtures = DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->where('round', $round)->where('is_bye', false)->get();
        $clubs = DB::table('clubs')->where('league_id', $league->id)->get(['id', 'name', 'strength_snapshot'])->keyBy('id');
        $matches = DB::table('matches')->whereIn('fixture_id', $fixtures->pluck('id'))->pluck('id', 'fixture_id');
        $results = $fixtures->map(fn ($f) => ['home' => $clubs[$f->home_id]->name, 'away' => $clubs[$f->away_id]->name,
            'home_goals' => (int) $f->home_goals, 'away_goals' => (int) $f->away_goals, 'match_id' => $matches[$f->id] ?? null])->values();

        $team = self::teamOfTheWeek($matches->values()->all());

        return ['round' => $round, 'rounds' => $played->sort()->values()->all(), 'results' => $results,
            'stories' => self::stories($fixtures, $clubs, $matches), 'team' => $team,
            'best_matches' => self::bestMatches($fixtures, $clubs, $matches), 'player' => self::playerOfTheRound($fixtures, $matches),
            'coach' => self::coachOfTheRound($fixtures, $clubs), 'scandals' => self::scandals($season->id)];
    }

    /** The round's matches most worth watching again (NewsFormulas::match), best first. */
    private static function bestMatches($fixtures, $clubs, $matches): array
    {
        $w = config('game.press.news');
        $weights = $w['match'] + ['upset_gap' => $w['upset_gap']];
        // The goals in order and the red cards of every match of the round, in one query.
        $events = DB::table('match_events')->whereIn('match_id', $matches->values())->whereIn('type', ['goal', 'card'])->orderBy('id')
            ->get(['match_id', 'type', 'minute', 'club_id', 'payload'])->groupBy('match_id');

        return $fixtures->map(function ($f) use ($weights, $clubs, $matches, $events) {
            $own = $events[$matches[$f->id] ?? 0] ?? collect();
            $goals = $own->where('type', 'goal')->map(fn ($e) => ['minute' => (int) $e->minute, 'side' => (int) $e->club_id === (int) $f->home_id ? 'home' : 'away'])->values()->all();
            $reds = $own->where('type', 'card')->filter(fn ($e) => (json_decode($e->payload, true)['color'] ?? null) === 'red')->count();
            $score = NewsFormulas::match(['home_goals' => (int) $f->home_goals, 'away_goals' => (int) $f->away_goals,
                'home_strength' => (int) $clubs[$f->home_id]->strength_snapshot, 'away_strength' => (int) $clubs[$f->away_id]->strength_snapshot], $goals, $reds, $weights);
            $diff = $f->home_goals - $f->away_goals;
            $loserStronger = $diff > 0 ? $clubs[$f->away_id]->strength_snapshot - $clubs[$f->home_id]->strength_snapshot : $clubs[$f->home_id]->strength_snapshot - $clubs[$f->away_id]->strength_snapshot;

            return ['score' => $score, 'home' => $clubs[$f->home_id]->name, 'away' => $clubs[$f->away_id]->name, 'home_goals' => (int) $f->home_goals,
                'away_goals' => (int) $f->away_goals, 'upset' => $diff !== 0 && $loserStronger >= $weights['upset_gap'],
                'comeback' => NewsFormulas::comeback($goals, $f->home_goals <=> $f->away_goals), 'match_id' => $matches[$f->id] ?? null];
        })->sortByDesc('score')->take((int) config('game.press.news.best_matches'))->values()->all();
    }

    /** The round's player (NewsFormulas::player): his rating, goals, assists, clean sheet and his side's result. */
    private static function playerOfTheRound($fixtures, $matches): ?array
    {
        $w = config('game.press.news.player');
        $byMatch = $fixtures->keyBy(fn ($f) => $matches[$f->id] ?? 0);
        $best = null;
        foreach (DB::table('match_stats')->whereIn('match_id', $matches->values())->get() as $s) {
            $f = $byMatch[$s->match_id] ?? null;
            if (! $f) {
                continue;
            }
            $home = (int) $s->club_id === (int) $f->home_id;
            [$for, $against] = $home ? [(int) $f->home_goals, (int) $f->away_goals] : [(int) $f->away_goals, (int) $f->home_goals];
            foreach (json_decode($s->players, true) as $p) {
                if (empty($p['played'])) {
                    continue;
                }
                $row = ['id' => (int) $p['id'], 'club_id' => (int) $s->club_id, 'rating' => (int) $p['rating'], 'goals' => (int) $p['goals'], 'assists' => (int) ($p['assists'] ?? 0),
                    'conceded' => $against, 'result' => $for <=> $against];
                $candidates[] = $row;
            }
        }
        if (empty($candidates)) {
            return null;
        }
        $lines = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->whereIn('players.id', array_column($candidates, 'id'))
            ->get(['players.id', 'master_players.name', 'master_players.line', 'master_players.position'])->keyBy('id');
        foreach ($candidates as $c) {
            $info = $lines[$c['id']] ?? null;
            if (! $info) {
                continue;
            }
            $score = NewsFormulas::player($c + ['line' => $info->line], $w);
            if (! $best || $score > $best['score'] || ($score === $best['score'] && $c['rating'] > $best['rating'])) {
                $best = ['score' => $score, 'id' => $c['id'], 'name' => $info->name, 'line' => $info->line, 'position' => $info->position,
                    'club' => (string) DB::table('clubs')->where('id', $c['club_id'])->value('name'), 'rating' => $c['rating'], 'goals' => $c['goals'], 'assists' => $c['assists']];
            }
        }

        return $best;
    }

    /** The coach whose result said most (NewsFormulas::coach); a coached side only, never one that lost. */
    private static function coachOfTheRound($fixtures, $clubs): ?array
    {
        $w = config('game.press.news.coach') + ['upset_gap' => config('game.press.news.upset_gap')];
        $coaches = DB::table('clubs')->join('users', 'users.id', '=', 'clubs.user_id')->whereIn('clubs.id', $clubs->keys())->get(['clubs.id', 'users.id as user_id', 'users.name'])->keyBy('id');
        $best = null;
        foreach ($fixtures as $f) {
            foreach ([[$f->home_id, $f->away_id, (int) $f->home_goals, (int) $f->away_goals, false], [$f->away_id, $f->home_id, (int) $f->away_goals, (int) $f->home_goals, true]] as [$club, $other, $for, $against, $away]) {
                if (! isset($coaches[$club])) {
                    continue;
                }
                $score = NewsFormulas::coach(['for' => $for, 'against' => $against, 'strength' => (int) $clubs[$club]->strength_snapshot,
                    'opponent_strength' => (int) $clubs[$other]->strength_snapshot, 'away' => $away], $w);
                if ($score !== null && (! $best || $score > $best['score'])) {
                    $best = ['score' => $score, 'coach' => ['id' => (int) $coaches[$club]->user_id, 'name' => $coaches[$club]->name], 'club' => $clubs[$club]->name,
                        'opponent' => $clubs[$other]->name, 'goals' => [$for, $against], 'away' => $away];
                }
            }
        }

        return $best;
    }

    /** The bribes an opponent exposed this season: the FA's verdicts, newest first. */
    private static function scandals(int $seasonId): array
    {
        return DB::table('fa_cases')->join('clubs', 'clubs.id', '=', 'fa_cases.accused_club_id')->leftJoin('users', 'users.id', '=', 'clubs.user_id')
            ->join('clubs as accuser', 'accuser.id', '=', 'fa_cases.accuser_club_id')->where('fa_cases.season_id', $seasonId)
            ->orderByDesc('fa_cases.id')->limit((int) config('game.press.news.scandals'))
            ->get(['clubs.name as club', 'users.name as coach', 'accuser.name as accuser', 'fa_cases.points', 'fa_cases.fine', 'fa_cases.created_at'])
            ->map(fn ($c) => ['club' => $c->club, 'coach' => $c->coach, 'accuser' => $c->accuser, 'points' => (int) $c->points, 'fine' => (int) $c->fine,
                'at' => Carbon::parse($c->created_at, 'UTC')->toIso8601ZuluString()])->all();
    }

    /** The round's big stories, as headlines. */
    private static function stories($fixtures, $clubs, $matches): array
    {
        $out = [];
        $name = fn ($id) => $clubs[$id]->name ?? '';
        $big = $fixtures->sortByDesc(fn ($f) => abs($f->home_goals - $f->away_goals) * 10 + $f->home_goals + $f->away_goals)->first();
        if ($big && $big->home_goals !== $big->away_goals) {
            [$w, $l] = $big->home_goals > $big->away_goals ? [$big->home_id, $big->away_id] : [$big->away_id, $big->home_id];
            $out[] = ['kind' => 'big_win', 'title' => sprintf(__('%s يكتسح %s'), $name($w), $name($l)), 'text' => sprintf(__('أكبر انتصار في الجولة: %d-%d.'), $big->home_goals, $big->away_goals)];
        }
        $upset = $fixtures->filter(function ($f) use ($clubs) {
            if ($f->home_goals === $f->away_goals) {
                return false;
            }
            [$w, $l] = $f->home_goals > $f->away_goals ? [$f->home_id, $f->away_id] : [$f->away_id, $f->home_id];

            return $clubs[$l]->strength_snapshot - $clubs[$w]->strength_snapshot >= 300;
        })->sortByDesc(fn ($f) => abs($clubs[$f->home_id]->strength_snapshot - $clubs[$f->away_id]->strength_snapshot))->first();
        if ($upset) {
            [$w, $l] = $upset->home_goals > $upset->away_goals ? [$upset->home_id, $upset->away_id] : [$upset->away_id, $upset->home_id];
            $out[] = ['kind' => 'upset', 'title' => sprintf(__('مفاجأة الجولة: %s يُسقط %s'), $name($w), $name($l)),
                'text' => sprintf(__('الأضعف على الورق فاز %d-%d، وكرة القدم لا تعترف بالأرقام.'), $upset->home_goals, $upset->away_goals)];
        }
        $feast = $fixtures->sortByDesc(fn ($f) => $f->home_goals + $f->away_goals)->first();
        if ($feast && $feast->home_goals + $feast->away_goals >= 5) {
            $out[] = ['kind' => 'goals', 'title' => sprintf(__('مهرجان أهداف بين %s و%s'), $name($feast->home_id), $name($feast->away_id)),
                'text' => sprintf(__('%d أهداف في مباراة واحدة.'), $feast->home_goals + $feast->away_goals)];
        }
        $reds = DB::table('match_events')->whereIn('match_id', $matches->values())->where('type', 'card')->whereLike('payload', '%"red"%')->count();
        if ($reds) {
            $out[] = ['kind' => 'reds', 'title' => $reds === 1 ? __('بطاقة حمراء تهز الجولة') : sprintf(__('%d بطاقات حمراء في جولة ساخنة'), $reds), 'text' => __('الحكام لم يرحموا أحداً هذه الجولة.')];
        }
        foreach (DB::table('match_stats')->whereIn('match_id', $matches->values())->get() as $s) {
            foreach (json_decode($s->players, true) as $p) {
                if (($p['goals'] ?? 0) >= 3) {
                    $who = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.id', $p['id'])->value('master_players.name');
                    $out[] = ['kind' => 'hat_trick', 'title' => sprintf(__('هاتريك لـ%s'), $who), 'text' => sprintf(__('%d أهداف لـ%s مع %s.'), $p['goals'], $who, $name($s->club_id))];
                }
            }
        }

        return $out;
    }

    /** The best rated of the round, by line: a keeper, four defenders, three midfielders and three forwards. */
    private static function teamOfTheWeek(array $matchIds): array
    {
        $rated = [];
        foreach (DB::table('match_stats')->whereIn('match_id', $matchIds)->get() as $s) {
            foreach (json_decode($s->players, true) as $p) {
                if (! empty($p['played'])) {
                    $rated[] = ['id' => (int) $p['id'], 'club_id' => (int) $s->club_id, 'rating' => (int) $p['rating'], 'goals' => (int) $p['goals']];
                }
            }
        }
        if (! $rated) {
            return [];
        }
        $info = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->whereIn('players.id', array_column($rated, 'id'))->get(['players.id', 'master_players.name', 'master_players.line', 'master_players.position'])->keyBy('id');
        $clubs = DB::table('clubs')->whereIn('id', array_column($rated, 'club_id'))->pluck('name', 'id');
        usort($rated, fn ($a, $b) => $b['rating'] <=> $a['rating'] ?: $b['goals'] <=> $a['goals'] ?: $a['id'] <=> $b['id']);
        $team = [];
        $left = self::SHAPE;
        foreach ($rated as $r) {
            $line = $info[$r['id']]->line ?? null;
            if ($line && ($left[$line] ?? 0) > 0) {
                $left[$line]--;
                $team[] = ['id' => $r['id'], 'name' => $info[$r['id']]->name, 'line' => $line, 'position' => $info[$r['id']]->position,
                    'club' => $clubs[$r['club_id']] ?? '', 'rating' => $r['rating']];
            }
        }
        usort($team, fn ($a, $b) => array_search($a['line'], array_keys(self::SHAPE)) <=> array_search($b['line'], array_keys(self::SHAPE)));

        return $team;
    }

    /** The published articles, newest first. */
    public static function articles(int $leagueId, string $status = 'published', int $limit = 30): array
    {
        return DB::table('league_articles')->join('users', 'users.id', '=', 'league_articles.user_id')->where('league_articles.league_id', $leagueId)
            ->where('league_articles.status', $status)->orderByDesc('league_articles.id')->limit($limit)
            ->get(['league_articles.id', 'league_articles.title', 'league_articles.body', 'league_articles.status', 'league_articles.created_at', 'users.id as user_id', 'users.name', 'users.username'])
            ->map(fn ($a) => ['id' => $a->id, 'title' => $a->title, 'body' => $a->body, 'status' => $a->status,
                'author' => ['id' => $a->user_id, 'name' => $a->name, 'username' => $a->username],
                'at' => Carbon::parse($a->created_at, 'UTC')->toIso8601ZuluString()])->all();
    }

    /** A coach's article goes to the league's owner, who publishes or turns it down. */
    public static function write(League $league, int $userId, string $title, string $body): int
    {
        [$seasonId, $round] = self::writingRound($league->id);
        // [Sprint 21 E4.5] One article a round for each coach, whatever became of it.
        abort_if(DB::table('league_articles')->where('league_id', $league->id)->where('user_id', $userId)->where('season_id', $seasonId)->where('round', $round)->exists(),
            409, sprintf(__('لك مقال واحد في كل جولة، وكتبت مقال الجولة %d.'), $round));
        $now = GameClock::now();
        $id = DB::table('league_articles')->insertGetId(['league_id' => $league->id, 'user_id' => $userId, 'title' => $title, 'body' => $body,
            'status' => 'pending', 'season_id' => $seasonId, 'round' => $round, 'created_at' => $now, 'updated_at' => $now]);
        if ($league->owner_id !== $userId) {
            $author = DB::table('users')->where('id', $userId)->value('name');
            Inbox::send($league->owner_id, 'article_pending', ['title' => $title, 'author' => $author, 'league' => $league->name, 'league_id' => $league->id], $league->id);
        }

        return $id;
    }

    /** The round an article now belongs to: the next one to be played, or the last of a finished season. [season, round] */
    public static function writingRound(int $leagueId): array
    {
        $season = DB::table('seasons')->where('league_id', $leagueId)->orderByDesc('number')->value('id');
        if (! $season) {
            return [null, 0];
        }
        $league = DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('is_bye', false);
        $round = (clone $league)->whereIn('status', ['scheduled', 'locked', 'live'])->min('round') ?? (clone $league)->max('round');

        return [(int) $season, (int) $round];
    }

    /** Whether this coach has written this round's article. */
    public static function wroteThisRound(int $leagueId, int $userId): bool
    {
        [$season, $round] = self::writingRound($leagueId);

        return DB::table('league_articles')->where('league_id', $leagueId)->where('user_id', $userId)->where('season_id', $season)->where('round', $round)->exists();
    }

    public static function decide(League $league, int $articleId, bool $publish): void
    {
        $changed = DB::table('league_articles')->where('id', $articleId)->where('league_id', $league->id)->where('status', 'pending')
            ->update(['status' => $publish ? 'published' : 'rejected', 'decided_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        if ($changed !== 1) {
            throw new HttpException(409, 'قُرر في هذا المقال من قبل.');
        }
    }
}
