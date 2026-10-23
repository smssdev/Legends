<?php

namespace App\Economy;

/**
 * The economy's numbers [PLAN 2.7, Sprint 23], pure and in integers: the game and sim:economy both use them,
 * so the simulation measures the real rules. The shares come from config('game.economy').
 */
class Money
{
    public function __construct(private array $cfg) {}

    public static function fromConfig(): self
    {
        return new self(config('game.economy'));
    }

    /** One league round of wages: the season's share of the squad's value, over the rounds. */
    public function wages(int $squadValue, int $rounds): int
    {
        return intdiv($squadValue * $this->cfg['wages_bp_per_season'], 10000 * max(1, $rounds));
    }

    /** What one home match brings at full attendance, before the sponsors' and tickets' split. */
    public function homeMatch(int $scale, int $rounds): int
    {
        return intdiv($scale * $this->cfg['home_income_bp_per_season'], 10000 * max(1, intdiv($rounds, 2)));
    }

    /** The sponsor money of one sector for one home match, by the chosen offer. */
    public function sponsor(int $scale, int $rounds, string $sector, string $offer, bool $won): int
    {
        $sectorMoney = intdiv($this->homeMatch($scale, $rounds) * $this->cfg['sponsor_share_bp'] * $this->cfg['sectors'][$sector], 10000 * 10000);
        $o = $this->cfg['sponsor_offers'][$offer];

        return intdiv($sectorMoney * ($o['fixed_bp'] + ($won ? $o['win_bp'] : 0)), 10000);
    }

    /** Attendance (basis points of the seats) from the club's strength between the league's weakest and strongest. */
    public function attendance(int $strength, int $min, int $max): int
    {
        $st = $this->cfg['stadium'];
        if ($max <= $min) {
            return intdiv($st['attendance_min_bp'] + $st['attendance_max_bp'], 2);
        }

        return $st['attendance_min_bp'] + intdiv(($st['attendance_max_bp'] - $st['attendance_min_bp']) * ($strength - $min), $max - $min);
    }

    /** The seat price, so that a full stadium brings the tickets' share. */
    public function ticketPrice(int $scale, int $rounds): int
    {
        return intdiv($this->homeMatch($scale, $rounds) * (10000 - $this->cfg['sponsor_share_bp']), 10000 * $this->cfg['stadium']['capacity']);
    }

    /** The gate of one home match: the seats filled at the price. More seats (the stadium's seats section) sell more. */
    public function tickets(int $scale, int $rounds, int $attendanceBp, ?int $capacity = null): int
    {
        return intdiv(($capacity ?? $this->cfg['stadium']['capacity']) * $attendanceBp, 10000) * $this->ticketPrice($scale, $rounds);
    }

    /** A league match's bonus: a win, a draw, or nothing. */
    public function resultBonus(int $scale, int $goalsFor, int $goalsAgainst): int
    {
        $bp = $goalsFor > $goalsAgainst ? $this->cfg['win_bonus_bp'] : ($goalsFor === $goalsAgainst ? $this->cfg['draw_bonus_bp'] : 0);

        return intdiv($scale * $bp, 10000);
    }

    /** The league prize for a final place (1 = champion). */
    public function leaguePrize(int $scale, int $place): int
    {
        return intdiv($scale * ($this->cfg['league_prize_bp'][$place - 1] ?? 0), 10000);
    }

    /** The cup prize: winner, final (the runner-up) or sf (a semi-finalist). */
    public function cupPrize(int $scale, string $reached): int
    {
        return intdiv($scale * ($this->cfg['cup_prize_bp'][$reached] ?? 0), 10000);
    }

    /** What the pool pays for a player: 70% of his value without his training [PLAN 2.7]. */
    public function poolPays(int $baseValue): int
    {
        return intdiv($baseValue * $this->cfg['sell_to_pool_bp'], 10000);
    }
}
