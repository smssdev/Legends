<?php

namespace App\Market;

use App\Economy\Contracts;
use App\League\ClubLedger;
use App\League\ClubStrength;
use App\League\Integrity;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [X61 E2] Loans between coaches: a coach asks another coach's player for 1 to max_rounds league rounds, for a fee
 * up to max_fee_bp of his value; the owner accepts (the fee is paid and the player moves) or turns it down. When the
 * league has played the loan's last round he goes home, by himself. A season's end sends every player home anyway.
 */
class Loans
{
    public static function ask(object $borrower, int $playerId, int $rounds, int $fee): int
    {
        Integrity::assertMarket($borrower->id);
        Market::assertOpen($borrower->league_id);
        $cfg = config('game.loans');
        $p = DB::table('players')->where('id', $playerId)->where('league_id', $borrower->league_id)->first();
        abort_unless($p && $p->club_id, 404, __('اللاعب غير موجود في هذا الدوري.'));
        $owner = DB::table('clubs')->where('id', $p->club_id)->first();
        if ($owner->id === $borrower->id || ! $owner->user_id) {
            throw new HttpException(409, 'الإعارة من نادي مدرب آخر فقط.');
        }
        if ($rounds < 1 || $rounds > (int) $cfg['max_rounds'] || $fee < 0 || $fee > intdiv((int) $p->value * (int) $cfg['max_fee_bp'], 10000)) {
            throw new HttpException(422, sprintf(__('الإعارة من جولة إلى %d جولات، ومقابلها حتى %d%% من قيمة اللاعب.'), (int) $cfg['max_rounds'], intdiv((int) $cfg['max_fee_bp'], 100)));
        }
        $season = DB::table('seasons')->where('league_id', $borrower->league_id)->orderByDesc('number')->first();
        if (! $season) {
            throw new HttpException(409, 'لا موسم في هذا الدوري بعد.');
        }
        if (DB::table('player_loans')->where('player_id', $playerId)->whereIn('status', ['pending', 'active'])->exists()) {
            throw new HttpException(409, 'على هذا اللاعب طلب إعارة أو إعارة جارية.');
        }
        $id = DB::table('player_loans')->insertGetId(['season_id' => $season->id, 'player_id' => $playerId, 'owner_club_id' => $owner->id,
            'borrower_club_id' => $borrower->id, 'rounds' => $rounds, 'fee' => $fee, 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        Inbox::send($owner->user_id, 'loan', self::payload($id, 'asked'), $borrower->league_id, $owner->id);

        return $id;
    }

    /** The owner's answer. Accepted: the fee is paid, the player moves until the round. */
    public static function answer(object $owner, int $loanId, bool $yes): void
    {
        DB::transaction(function () use ($owner, $loanId, $yes) {
            $l = DB::table('player_loans')->where('id', $loanId)->where('owner_club_id', $owner->id)->where('status', 'pending')->first();
            abort_unless($l, 404, __('لا طلب إعارة بهذا الرقم ينتظرك.'));
            if (! $yes) {
                DB::table('player_loans')->where('id', $loanId)->update(['status' => 'rejected', 'updated_at' => GameClock::now()]);
            } else {
                Market::assertOpen($owner->league_id);
                Contracts::assertRoom((int) $l->borrower_club_id, (int) DB::table('players')->where('id', $l->player_id)->value('value'));
                $played = (int) DB::table('seasons')->where('id', $l->season_id)->value('rounds_played');
                if (DB::table('player_loans')->where('id', $loanId)->where('status', 'pending')->update(['status' => 'active', 'until_round' => $played + $l->rounds, 'updated_at' => GameClock::now()]) !== 1
                    || DB::table('players')->where('id', $l->player_id)->where('club_id', $owner->id)->update(['club_id' => $l->borrower_club_id, 'updated_at' => GameClock::now()]) !== 1) {
                    throw new HttpException(409, 'لم يعد اللاعب متاحاً للإعارة.');
                }
                Transfers::left($l->player_id, $owner->id);
                ClubStrength::refresh((int) $l->borrower_club_id);   // [X98]
                if ($l->fee > 0) {
                    ClubLedger::post($l->borrower_club_id, 'loan_fee', -(int) $l->fee, "loan:{$loanId}:pay", "loan:{$loanId}", spend: true);
                    ClubLedger::post($owner->id, 'loan_fee', (int) $l->fee, "loan:{$loanId}:get", "loan:{$loanId}");
                }
            }
            $borrower = DB::table('clubs')->where('id', $l->borrower_club_id)->first();
            Inbox::send($borrower->user_id, 'loan', self::payload($loanId, $yes ? 'accepted' : 'rejected'), $borrower->league_id, $borrower->id);
        });
    }

    /** After a league round: every loan whose last round is played sends its player home. */
    public static function returnDue(int $seasonId): int
    {
        $played = (int) DB::table('seasons')->where('id', $seasonId)->value('rounds_played');
        $back = 0;
        foreach (DB::table('player_loans')->where('season_id', $seasonId)->where('status', 'active')->where('until_round', '<=', $played)->get() as $l) {
            DB::transaction(function () use ($l, &$back) {
                if (DB::table('player_loans')->where('id', $l->id)->where('status', 'active')->update(['status' => 'returned', 'updated_at' => GameClock::now()]) === 1) {
                    DB::table('players')->where('id', $l->player_id)->where('club_id', $l->borrower_club_id)->update(['club_id' => $l->owner_club_id, 'updated_at' => GameClock::now()]);
                    Transfers::left($l->player_id, $l->borrower_club_id);
                    ClubStrength::refresh((int) $l->owner_club_id);   // [X98]
                    $back++;
                }
            });
        }

        return $back;
    }

    /** A coach's loans this season: asked of him, asked by him, and running either way. */
    public static function of(object $club): array
    {
        $rows = DB::table('player_loans')->join('players', 'players.id', '=', 'player_loans.player_id')
            ->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where(fn ($q) => $q->where('owner_club_id', $club->id)->orWhere('borrower_club_id', $club->id))
            ->whereIn('player_loans.status', ['pending', 'active'])->orderByDesc('player_loans.id')
            ->get(['player_loans.*', 'master_players.name', 'master_players.position']);
        $names = DB::table('clubs')->whereIn('id', $rows->pluck('owner_club_id')->merge($rows->pluck('borrower_club_id')))->pluck('name', 'id');

        return $rows->map(fn ($l) => ['id' => (int) $l->id, 'status' => $l->status, 'mine' => (int) $l->owner_club_id === $club->id,
            'player' => ['id' => (int) $l->player_id, 'name' => $l->name, 'position' => $l->position],
            'owner' => $names[$l->owner_club_id] ?? '', 'borrower' => $names[$l->borrower_club_id] ?? '',
            'rounds' => (int) $l->rounds, 'fee' => (int) $l->fee, 'until_round' => $l->until_round !== null ? (int) $l->until_round : null])->all();
    }

    private static function payload(int $loanId, string $what): array
    {
        $l = DB::table('player_loans')->where('id', $loanId)->first();
        $player = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.id', $l->player_id)->value('master_players.name');

        return ['what' => $what, 'player' => $player, 'from' => DB::table('clubs')->where('id', $l->borrower_club_id)->value('name'),
            'rounds' => (int) $l->rounds, 'money' => (int) $l->fee];
    }
}
