<?php

namespace Tests\Unit;

use App\Season\CoachRating;
use Tests\TestCase;

/** [Sprint 25] The coach's rating: the points of a result by the opponent's strength, the kept tiers, and the divisions. */
class CoachRatingTest extends TestCase
{
    private function w(): array
    {
        return config('game.rating');
    }

    private function m(int $for, int $against, int $gap = 0, bool $away = false): array
    {
        return ['for' => $for, 'against' => $against, 'strength' => 8000, 'opponent_strength' => 8000 + $gap, 'away' => $away];
    }

    public function test_a_win_rises_a_loss_falls_and_an_even_draw_rises_a_little(): void
    {
        $w = $this->w();
        $this->assertSame($w['win'], CoachRating::delta($this->m(1, 0), $w));
        $this->assertSame($w['draw'], CoachRating::delta($this->m(1, 1), $w));
        $this->assertSame($w['loss'], CoachRating::delta($this->m(0, 1), $w));
        $this->assertGreaterThan(0, $w['win']);
        $this->assertLessThan(0, $w['loss']);
    }

    public function test_the_opponents_strength_makes_it_fair(): void
    {
        $w = $this->w();
        $strong = 2 * $w['step_cp'];
        // Beating a stronger side pays more, a weaker one less.
        $this->assertSame($w['win'] + 2 * $w['per_step']['win'], CoachRating::delta($this->m(2, 1, $strong), $w));
        $this->assertSame($w['win'] - 2 * $w['per_step']['win'], CoachRating::delta($this->m(2, 1, -$strong), $w));
        // Losing to a stronger side costs less, to a weaker one more.
        $this->assertSame($w['loss'] + 2 * $w['per_step']['loss'], CoachRating::delta($this->m(0, 1, $strong), $w));
        $this->assertSame($w['loss'] - 2 * $w['per_step']['loss'], CoachRating::delta($this->m(0, 1, -$strong), $w));
        // A draw with the much weaker side is a loss of points; with the much stronger a gain.
        $this->assertLessThan(0, CoachRating::delta($this->m(0, 0, -$w['max_steps'] * $w['step_cp']), $w));
        $this->assertGreaterThan($w['draw'], CoachRating::delta($this->m(0, 0, $strong), $w));
        // The gap counts up to max_steps, and less than a step counts nothing, either way.
        $this->assertSame(CoachRating::delta($this->m(1, 0, $w['max_steps'] * $w['step_cp']), $w), CoachRating::delta($this->m(1, 0, 10 * $w['max_steps'] * $w['step_cp']), $w));
        $this->assertSame($w['win'], CoachRating::delta($this->m(1, 0, $w['step_cp'] - 1), $w));
        $this->assertSame($w['win'], CoachRating::delta($this->m(1, 0, 1 - $w['step_cp']), $w));
        // Even at the widest gap a win still rises and a loss still falls.
        $this->assertGreaterThan(0, CoachRating::delta($this->m(1, 0, -10_000), $w));
        $this->assertLessThan(0, CoachRating::delta($this->m(0, 1, 10_000), $w));
    }

    public function test_away_and_a_big_win_add(): void
    {
        $w = $this->w();
        $this->assertSame($w['win'] + $w['away'], CoachRating::delta($this->m(1, 0, 0, true), $w));
        $this->assertSame($w['draw'] + $w['away'], CoachRating::delta($this->m(2, 2, 0, true), $w));
        $this->assertSame($w['loss'], CoachRating::delta($this->m(0, 1, 0, true), $w));
        $this->assertSame($w['win'] + $w['big_win'], CoachRating::delta($this->m($w['big_margin'], 0), $w));
        $this->assertSame($w['trophies']['league'][1], CoachRating::trophy('league', 1, $w));
        $this->assertSame(0, CoachRating::trophy('cup', 3, $w));
    }

    public function test_never_below_zero_nor_below_a_tier_reached(): void
    {
        $w = $this->w();
        $this->assertSame(['points' => 0, 'peak' => 0, 'applied' => [0, 0]], CoachRating::apply([-14, -14], $w));
        $pro = $w['tiers']['professional'];
        // Up to the professional's start and a little more, then a long bad run: back to its start, not under.
        $run = CoachRating::apply([$pro + 10, -14, -14, -14], $w);
        $this->assertSame($pro, $run['points']);
        $this->assertSame($pro + 10, $run['peak']);
        $this->assertSame([$pro + 10, -10, 0, 0], $run['applied']);
        $this->assertSame('professional', CoachRating::tier($run['points'], $w)['key']);
    }

    public function test_the_tiers_and_their_divisions(): void
    {
        $w = $this->w();
        $t = CoachRating::tier(0, $w);
        $this->assertSame(['prospect', 1, 3, 0, 50], [$t['key'], $t['rank'], $t['division'], $t['from'], $t['next']]);
        // The tactician (150 to 400): III to 233, II to 316, I to 400.
        $this->assertSame(3, CoachRating::tier(150, $w)['division']);
        $this->assertSame(2, CoachRating::tier(233, $w)['division']);
        $mid = CoachRating::tier(399, $w);
        $this->assertSame([1, 316, 400], [$mid['division'], $mid['from'], $mid['next']]);
        $this->assertSame(9880, $mid['progress_bp']);
        $this->assertSame(3, CoachRating::tier(232, $w)['division']);
        $legend = CoachRating::tier(99_999, $w);
        $this->assertSame(['legend', 7, null, null, 10000], [$legend['key'], $legend['rank'], $legend['division'], $legend['next'], $legend['progress_bp']]);
        $this->assertSame(array_keys($w['tiers']), array_column(CoachRating::ladder(), 'key'));
    }
}
