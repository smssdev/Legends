<?php

namespace App\League;

use App\Market\Pool;
use App\Models\Club;
use App\Models\League;
use App\Staff\Specialists;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * A coach's agenda in one club [Sprint 20 B1, W3, W4]: everything in the game that runs on a clock (the timers), and
 * what is waiting for the coach to do (the to-do list), the most urgent first. Read by the club board, the top bar's
 * two windows and the home screen's slots, so they all say the same. Nothing of the opponent's private tactics.
 */
class ClubAgenda
{
    /**
     * Every clock of this club, soonest first: kind (match, training, stadium, scout, daily, market), when it ends
     * (UTC, null when ready now), and what it is about.
     */
    public static function timers(Club $club, League $league, int $userId): array
    {
        $out = [];
        $at = fn ($v) => $v ? Carbon::parse($v, 'UTC')->toIso8601ZuluString() : null;
        if ($f = self::nextFixture($club)) {
            $out[] = ['kind' => 'match', 'at' => $at($f->scheduled_at), 'live' => $f->status === 'live',
                'opponent' => DB::table('clubs')->where('id', $f->home_id === $club->id ? $f->away_id : $f->home_id)->value('name')];
        }
        foreach (DB::table('training_slots')->join('players', 'players.id', '=', 'training_slots.player_id')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('training_slots.club_id', $club->id)->get(['training_slots.line', 'training_slots.next_at', 'master_players.name']) as $s) {
            $out[] = ['kind' => 'training', 'at' => $at($s->next_at), 'line' => $s->line, 'player' => $s->name];
        }
        if ($b = DB::table('stadium_builds')->where('club_id', $club->id)->where('status', 'building')->first()) {
            $out[] = ['kind' => 'stadium', 'at' => $at($b->ends_at), 'section' => $b->section, 'part' => (int) $b->part, 'stage' => (int) $b->stage];
        }
        if ($r = DB::table('scout_requests')->where('club_id', $club->id)->where('status', 'searching')->orderBy('finishes_at')->first()) {
            $out[] = ['kind' => 'scout', 'at' => $at($r->finishes_at)];
        }
        // The daily coins: ready now, or at the next midnight in Cairo.
        $cairo = GameClock::now()->setTimezone('Africa/Cairo');
        $claimed = DB::table('wallet_transactions')->where('idempotency_key', "daily:{$userId}:".$cairo->toDateString())->exists();
        $out[] = ['kind' => 'daily', 'at' => $claimed ? $cairo->copy()->addDay()->startOfDay()->utc()->toIso8601ZuluString() : null, 'amount' => (int) config('game.premium.earn.daily')];
        if ($league->pool_renewed_at) {
            $out[] = ['kind' => 'market', 'at' => Pool::renewsAt($league)->toIso8601ZuluString()];
        }
        usort($out, fn ($a, $b) => [$a['at'] !== null, $a['at']] <=> [$b['at'] !== null, $b['at']]);

        return $out;
    }

    /**
     * What waits for the coach, the most urgent first: kind, severity (high, mid, low) and its details. Each one is
     * gone once done: a fixed lineup, a filled slot, an answered offer, a read message.
     */
    public static function pending(Club $club, League $league, int $userId): array
    {
        $out = [];
        $f = self::nextFixture($club);
        // A live match's tactical window waiting for this coach.
        if ($f && $f->status === 'live' && ($m = DB::table('matches')->where('fixture_id', $f->id)->value('id'))) {
            $pause = MatchRunner::pauseOf((int) $m);
            $side = $f->home_id === $club->id ? 'home' : 'away';
            if ($pause && ! in_array($side, $pause['ready'], true)) {
                $out[] = ['kind' => 'window', 'severity' => 'high', 'match_id' => (int) $m, 'until' => $pause['until']];
            }
        }
        // An injured or suspended starter before the lock (after it, the assistant has fixed the sheet).
        if ($f && $f->status === 'scheduled') {
            $starters = array_filter(TeamSheet::current($club)['starters']);
            $out_ = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->whereIn('players.id', $starters)
                ->where(fn ($q) => $q->where('players.injured_matches', '>', 0)->orWhere('players.suspended_matches', '>', 0))
                ->get(['players.id', 'master_players.name', 'players.injured_matches']);
            if ($out_->isNotEmpty()) {
                $out[] = ['kind' => 'lineup', 'severity' => 'high', 'players' => $out_->map(fn ($p) => ['id' => (int) $p->id, 'name' => $p->name, 'why' => $p->injured_matches > 0 ? 'injured' : 'suspended'])->values()->all()];
            }
        }
        $offers = DB::table('transfer_offers')->where('to_club_id', $club->id)->where('status', 'pending')->where('expires_at', '>', GameClock::now())->count();
        if ($offers) {
            $out[] = ['kind' => 'offers', 'severity' => 'mid', 'count' => $offers];
        }
        if ($league->owner_id === $userId && ($requests = DB::table('league_join_requests')->where('league_id', $league->id)->where('status', 'pending')->count())) {
            $out[] = ['kind' => 'requests', 'severity' => 'mid', 'count' => $requests];
        }
        // A training slot left empty while its line's coach is hired.
        $busy = DB::table('training_slots')->where('club_id', $club->id)->pluck('line')->all();
        $empty = array_values(array_filter(array_keys(Specialists::LINE_COACH), fn ($line) => ! in_array($line, $busy, true) && Specialists::has($club->id, Specialists::LINE_COACH[$line])));
        if ($empty) {
            $out[] = ['kind' => 'training_empty', 'severity' => 'low', 'lines' => $empty];
        }
        $done = DB::table('messages')->where('user_id', $userId)->where('league_id', $league->id)->where('type', 'training_done')->whereNull('read_at')->count();
        if ($done) {
            $out[] = ['kind' => 'training_done', 'severity' => 'low', 'count' => $done];
        }

        return $out;
    }

    /** The board's mood [Sprint 20, question 5]: the league place against its objective, after three rounds. */
    public static function board(Club $club, int $seasonId, ?int $position, int $played): ?array
    {
        $o = DB::table('club_objectives')->where('club_id', $club->id)->where('season_id', $seasonId)->where('competition', 'league')->first();
        if (! $o) {
            return null;
        }
        $target = (int) $o->target;
        $mood = $played < (int) config('game.board.after_rounds') || ! $position ? 'calm'
            : ($position <= $target ? 'happy' : ($position <= $target + (int) config('game.board.worried_places') ? 'worried' : 'angry'));

        return ['mood' => $mood, 'target' => $target, 'kind' => $o->kind, 'position' => $position];
    }

    public static function nextFixture(Club $club): ?object
    {
        return DB::table('fixtures')->whereIn('status', ['scheduled', 'locked', 'live'])->where('is_bye', false)->whereNotNull('home_id')->whereNotNull('away_id')
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->orderBy('scheduled_at')->first();
    }
}
