<?php

namespace App\Messenger;

use App\Assistant\Priorities;
use App\League\SeasonStats;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 68] The bot's other readings of a coach's clubs: his squad's absent and tired, the training, his matches to
 * come, the league's scorers, his unread messages, and the daily summary. Read only, from the game's own tables.
 */
class Reads
{
    private const LINES = ['gk' => ['الحراسة', 'Goalkeeping'], 'def' => ['الدفاع', 'Defence'], 'mid' => ['الوسط', 'Midfield'], 'att' => ['الهجوم', 'Attack']];

    /** The account's clubs in leagues not over, each with its league. */
    public static function clubs(int $userId)
    {
        return DB::table('clubs')->join('leagues', 'leagues.id', '=', 'clubs.league_id')->where('clubs.user_id', $userId)
            ->where('leagues.status', '!=', 'finished')->orderBy('clubs.id')
            ->get(['clubs.id', 'clubs.name', 'clubs.balance', 'leagues.id as league_id', 'leagues.name as league_name']);
    }

    public static function noClub(bool $en): string
    {
        return $en ? 'You coach no club now. Open the game to join or create a league.' : 'لا نادي لك الآن. افتح اللعبة وانضم إلى دوري أو أنشئ واحداً.';
    }

    /** "in 3 h 20 min": the time to it, so no time zone is needed. */
    public static function in(Carbon $at, bool $en): string
    {
        $min = max(0, (int) floor(GameClock::now()->diffInMinutes($at, false)));
        $d = intdiv($min, 1440);
        $h = intdiv($min % 1440, 60);
        $m = $min % 60;
        if ($en) {
            return 'in '.trim(($d ? "{$d} d " : '').($h ? "{$h} h " : '').($d ? '' : "{$m} min"));
        }

        return 'بعد '.implode(' و', array_filter([$d ? "{$d} يوم" : null, $h ? "{$h} ساعة" : null, $d ? null : "{$m} دقيقة"]));
    }

    public static function season(int $leagueId): ?int
    {
        $id = DB::table('seasons')->where('league_id', $leagueId)->orderByDesc('id')->value('id');

        return $id ? (int) $id : null;
    }

    /** Each club's injured and suspended players, and the tired (under 75% fitness). */
    public static function squad(int $userId, bool $en): string
    {
        $clubs = self::clubs($userId);
        if ($clubs->isEmpty()) {
            return self::noClub($en);
        }
        $out = [];
        foreach ($clubs as $c) {
            $players = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $c->id)
                ->where(fn ($q) => $q->where('players.injured_matches', '>', 0)->orWhere('players.suspended_matches', '>', 0)->orWhere('players.fitness', '<', 75))
                ->orderBy('master_players.name')->get(['master_players.name', 'players.injured_matches', 'players.suspended_matches', 'players.fitness']);
            $out[] = $c->name.':';
            if ($players->isEmpty()) {
                $out[] = $en ? 'Everyone is fit and available.' : 'كل اللاعبين جاهزون.';
            }
            foreach ($players as $p) {
                $out[] = '- '.$p->name.': '.implode('، ', array_filter([
                    $p->injured_matches > 0 ? ($en ? "injured ({$p->injured_matches} matches)" : "مصاب ({$p->injured_matches} مباريات)") : null,
                    $p->suspended_matches > 0 ? ($en ? "suspended ({$p->suspended_matches})" : "موقوف ({$p->suspended_matches})") : null,
                    $p->fitness < 75 ? ($en ? "fitness {$p->fitness}%" : "اللياقة {$p->fitness}%") : null,
                ]));
            }
        }

        return implode("\n", $out);
    }

    /** Each line's player in training, his sessions, and when the next one ends; an empty line says so. */
    public static function training(int $userId, bool $en): string
    {
        $clubs = self::clubs($userId);
        if ($clubs->isEmpty()) {
            return self::noClub($en);
        }
        $out = [];
        foreach ($clubs as $c) {
            $slots = DB::table('training_slots')->join('players', 'players.id', '=', 'training_slots.player_id')
                ->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('training_slots.club_id', $c->id)
                ->get(['training_slots.line', 'training_slots.sessions', 'training_slots.next_at', 'master_players.name'])->keyBy('line');
            $out[] = $c->name.':';
            foreach (self::LINES as $line => $label) {
                $s = $slots[$line] ?? null;
                $out[] = '- '.$label[$en ? 1 : 0].': '.($s
                    ? ($en ? "{$s->name}, {$s->sessions} sessions, the next ends " : "{$s->name}، {$s->sessions} جلسات، التالية تنتهي ").self::in(Carbon::parse($s->next_at), $en)
                    : ($en ? 'empty' : 'فارغة'));
            }
        }

        return implode("\n", $out);
    }

    /** The next five matches of each club, in any competition. */
    public static function fixtures(int $userId, bool $en): string
    {
        $clubs = self::clubs($userId);
        if ($clubs->isEmpty()) {
            return self::noClub($en);
        }
        $out = [];
        foreach ($clubs as $c) {
            $list = DB::table('fixtures')->whereIn('status', ['scheduled', 'locked', 'live'])->where('is_bye', false)
                ->where(fn ($q) => $q->where('home_id', $c->id)->orWhere('away_id', $c->id))->whereNotNull('home_id')->whereNotNull('away_id')
                ->orderBy('scheduled_at')->limit(5)->get();
            $names = DB::table('clubs')->whereIn('id', $list->pluck('home_id')->merge($list->pluck('away_id')))->pluck('name', 'id');
            $out[] = $c->name.':';
            if ($list->isEmpty()) {
                $out[] = $en ? 'No match scheduled.' : 'لا مباريات مجدولة.';
            }
            foreach ($list as $f) {
                $home = (int) $f->home_id === (int) $c->id;
                $out[] = '- '.($home ? '' : '@ ').$names[$home ? $f->away_id : $f->home_id].': '
                    .($f->status === 'live' ? ($en ? 'being played now' : 'تُلعب الآن') : self::in(Carbon::parse($f->scheduled_at), $en));
            }
        }

        return implode("\n", $out);
    }

    /** The top five scorers of each of his leagues this season. */
    public static function scorers(int $userId, bool $en): string
    {
        $clubs = self::clubs($userId)->unique('league_id');
        if ($clubs->isEmpty()) {
            return self::noClub($en);
        }
        $out = [];
        foreach ($clubs as $c) {
            $season = self::season((int) $c->league_id);
            $list = $season ? SeasonStats::of((int) $c->league_id, $season, 5)['scorers'] : [];
            $out[] = ($en ? "Top scorers, {$c->league_name}:" : "هدافو {$c->league_name}:");
            if (! $list) {
                $out[] = $en ? 'No goal yet.' : 'لا أهداف بعد.';
            }
            foreach ($list as $i => $r) {
                $out[] = ($i + 1).'. '.$r['player']['name'].' ('.$r['club']['name'].'): '.$r['goals'];
            }
        }

        return implode("\n", $out);
    }

    /** How many messages wait unread, and the last three of them. */
    public static function inbox(int $userId, string $locale, bool $en): string
    {
        $n = Inbox::unread($userId);
        if ($n === 0) {
            return $en ? 'No unread message.' : 'لا رسائل غير مقروءة.';
        }
        $out = [$en ? "{$n} unread messages. The latest:" : "عندك {$n} رسائل غير مقروءة. آخرها:"];
        foreach (DB::table('messages')->where('user_id', $userId)->whereNull('read_at')->orderByDesc('id')->limit(3)->get() as $m) {
            $v = Inbox::view($m, $locale);
            $out[] = '- '.trim(($v['title'] ?? '').(($v['body'] ?? '') !== '' ? ': '.$v['body'] : ''));
        }
        $out[] = rtrim((string) config('app.frontend_url'), '/').'/inbox';

        return implode("\n", $out);
    }

    /** [Sprint 68] The morning summary: today's matches, yesterday's results, and what waits for him now. */
    public static function daily(int $userId, string $locale): ?string
    {
        $en = $locale === 'en';
        $clubs = self::clubs($userId);
        if ($clubs->isEmpty()) {
            return null;
        }
        $cairo = GameClock::now()->setTimezone('Africa/Cairo');
        $today = [$cairo->copy()->startOfDay()->utc(), $cairo->copy()->endOfDay()->utc()];
        $yesterday = [$cairo->copy()->subDay()->startOfDay()->utc(), $cairo->copy()->subDay()->endOfDay()->utc()];
        $ids = $clubs->pluck('id')->all();
        $mine = fn ($q) => $q->whereIn('home_id', $ids)->orWhereIn('away_id', $ids);
        $played = DB::table('fixtures')->where('status', 'finished')->where('is_bye', false)->where($mine)->whereBetween('scheduled_at', $yesterday)->orderBy('scheduled_at')->get();
        $coming = DB::table('fixtures')->whereIn('status', ['scheduled', 'locked', 'live'])->where('is_bye', false)->where($mine)
            ->whereNotNull('home_id')->whereNotNull('away_id')->whereBetween('scheduled_at', $today)->orderBy('scheduled_at')->get();
        $names = DB::table('clubs')->whereIn('id', $played->pluck('home_id')->merge($played->pluck('away_id'))->merge($coming->pluck('home_id'))->merge($coming->pluck('away_id')))->pluck('name', 'id');
        $out = [$en ? 'Good morning, coach! Your day:' : 'صباح الخير يا مدرب! يومك:', ''];
        $out[] = $en ? 'Today:' : 'اليوم:';
        foreach ($coming as $f) {
            $out[] = "- {$names[$f->home_id]} - {$names[$f->away_id]}: ".($f->status === 'live' ? ($en ? 'now' : 'الآن') : self::in(Carbon::parse($f->scheduled_at), $en));
        }
        if ($coming->isEmpty()) {
            $out[] = $en ? '- No match today.' : '- لا مباراة لك اليوم.';
        }
        if ($played->isNotEmpty()) {
            $out[] = $en ? 'Yesterday:' : 'أمس:';
            foreach ($played as $f) {
                $out[] = "- {$names[$f->home_id]} {$f->home_goals} - {$f->away_goals} {$names[$f->away_id]}";
            }
        }
        $now = Priorities::answer('now', $userId, (int) $clubs->first()->league_id, $locale);
        if ($now) {
            $out[] = '';
            $out[] = $now['answer'];
        }

        return implode("\n", $out);
    }
}
