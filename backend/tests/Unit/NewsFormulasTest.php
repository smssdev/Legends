<?php

namespace Tests\Unit;

use App\League\NewsFormulas;
use Tests\TestCase;

/** [Sprint 20 S3] The league news' formulas: the best match, the player and the coach of the round. */
class NewsFormulasTest extends TestCase
{
    private function w(string $part): array
    {
        $news = config('game.press.news');

        return $news[$part] + ['upset_gap' => $news['upset_gap']];
    }

    public function test_a_late_comeback_beats_a_bigger_but_dull_win(): void
    {
        $m = fn ($h, $a) => ['home_goals' => $h, 'away_goals' => $a, 'home_strength' => 8000, 'away_strength' => 8000];
        // 4-0, goals all early.
        $dull = NewsFormulas::match($m(4, 0), array_fill(0, 4, ['minute' => 20, 'side' => 'home']), 0, $this->w('match'));
        // 3-2 for home after trailing 0-2, the equaliser at 86 and the winner at 90.
        $goals = [['minute' => 10, 'side' => 'away'], ['minute' => 30, 'side' => 'away'], ['minute' => 60, 'side' => 'home'], ['minute' => 86, 'side' => 'home'], ['minute' => 90, 'side' => 'home']];
        $this->assertSame(2, NewsFormulas::lateTurns($goals, 85));
        $this->assertTrue(NewsFormulas::comeback($goals, 1));
        $this->assertFalse(NewsFormulas::comeback($goals, 0));
        $drama = NewsFormulas::match($m(3, 2), $goals, 0, $this->w('match'));
        $this->assertGreaterThan($dull, $drama);
        // 3×5 goals + one-goal 3 + two late turns 6 + comeback 6.
        $this->assertSame(30, $drama);
    }

    public function test_a_surprise_counts_only_for_the_weaker_side(): void
    {
        $w = $this->w('match');
        $weakHomeWins = NewsFormulas::match(['home_goals' => 1, 'away_goals' => 0, 'home_strength' => 7000, 'away_strength' => 7500], [['minute' => 50, 'side' => 'home']], 0, $w);
        $strongHomeWins = NewsFormulas::match(['home_goals' => 1, 'away_goals' => 0, 'home_strength' => 7500, 'away_strength' => 7000], [['minute' => 50, 'side' => 'home']], 0, $w);
        $this->assertSame($w['upset'], $weakHomeWins - $strongHomeWins);
        $this->assertSame(0 + $w['upset_draw'], NewsFormulas::match(['home_goals' => 0, 'away_goals' => 0, 'home_strength' => 7000, 'away_strength' => 7500], [], 0, $w));
        $this->assertSame(2 * $w['red'], NewsFormulas::match(['home_goals' => 0, 'away_goals' => 0, 'home_strength' => 7000, 'away_strength' => 7000], [], 2, $w));
    }

    public function test_the_player_of_the_round_weighs_goals_assists_clean_sheets_and_the_result(): void
    {
        $w = $this->w('player');
        $p = fn (array $x) => NewsFormulas::player($x + ['rating' => 700, 'goals' => 0, 'assists' => 0, 'line' => 'mid', 'conceded' => 1, 'result' => 0], $w);
        $this->assertSame(700 + $w['draw'], $p([]));
        $this->assertSame(800 + 2 * $w['goal'] + $w['win'], $p(['rating' => 800, 'goals' => 2, 'result' => 1]));
        // A clean sheet counts for a keeper or a defender, not a forward.
        $this->assertSame($w['clean_sheet'], $p(['line' => 'gk', 'conceded' => 0]) - $p(['line' => 'att', 'conceded' => 0]));
        // A hat-trick in a defeat can still top a quiet win.
        $this->assertGreaterThan($p(['rating' => 720, 'result' => 1]), $p(['rating' => 850, 'goals' => 3, 'result' => -1]));
    }

    public function test_the_coach_of_the_round_never_lost_and_a_draw_counts_only_against_a_stronger_side(): void
    {
        $w = $this->w('coach');
        $c = fn (array $x) => NewsFormulas::coach($x + ['for' => 1, 'against' => 0, 'strength' => 7000, 'opponent_strength' => 7000, 'away' => false], $w);
        $this->assertNull($c(['for' => 0, 'against' => 1]));
        $this->assertNull($c(['for' => 1, 'against' => 1]));
        $this->assertSame($w['draw'] + 5, $c(['for' => 1, 'against' => 1, 'opponent_strength' => 7500]));
        // 1-0 at home, level sides: win + one goal + clean sheet.
        $this->assertSame($w['win'] + $w['margin'] + $w['clean_sheet'], $c([]));
        // The margin stops at margin_max goals.
        $this->assertSame($c(['for' => 3]), $c(['for' => 7]));
        // An away win by the weaker side beats a home win by the stronger one.
        $this->assertGreaterThan($c(['strength' => 8000]), $c(['away' => true, 'opponent_strength' => 8000]));
    }
}
