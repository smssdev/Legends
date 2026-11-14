<?php

namespace Tests\Feature;

use App\Models\MasterClub;
use App\Simulator\MatchFactory;
use App\Simulator\Report;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** A report always explains the result, even after a match that leaned neither way [ENGINE 8.1]. */
class ReportReasonsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    public function test_an_even_draw_still_has_reasons(): void
    {
        $this->template(2, full: true);
        [$home, $away] = MasterClub::orderBy('id')->get()->all();
        // Before kick-off: 0-0 and every number even, so no fact leans either way.
        $state = MatchFactory::make($home, $away, ['seed' => 1]);
        foreach (['home', 'away'] as $side) {
            $report = Report::build($state, [], $side);
            $this->assertSame('draw', $report['result']);
            $this->assertNotEmpty($report['reasons']);
        }
    }

    public function test_the_one_suggestion_says_where_to_act(): void
    {
        $this->template(2, full: true);
        [$home, $away] = MasterClub::orderBy('id')->get()->all();
        $state = MatchFactory::make($home, $away, ['seed' => 1]);
        // [Sprint 64 B6] Every reason knows where a coach acts on it; luck nowhere.
        $state['teams']['away']['stats']['big_chances'] = 6;   // the other side made the better chances
        $report = Report::build($state, [], 'home');
        foreach ($report['reasons'] as $r) {
            $this->assertContains($r['go'], ['lineup', 'plan', 'training', null]);
        }
        $this->assertNotNull($report['improve']);
        $this->assertArrayHasKey('go', $report['improve']);
    }
}
