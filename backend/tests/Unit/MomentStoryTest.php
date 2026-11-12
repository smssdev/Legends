<?php

namespace Tests\Unit;

use App\Simulator\MomentStory;
use Tests\TestCase;

/**
 * [Sprint 57 B2] The minute's story on the server tells what the web's story.ts told before it was deleted.
 *
 * Checked once on 50 whole matches (4884 minutes, every moment and drama, both languages, with the server's voice,
 * without it as in old replays, and with it given up under load): the web's text from story.ts was the same as
 * web/src/match/feed/told.ts writes from this story, minute by minute. The fixture keeps 256 of those minutes (up to
 * three of each moment, drama and voice case) with the story the server gave, so the port stays as it was.
 */
class MomentStoryTest extends TestCase
{
    public function test_the_story_is_the_one_the_web_told(): void
    {
        $rows = json_decode(file_get_contents(base_path('tests/fixtures/moment-story.json')), true);
        $this->assertCount(256, $rows);
        foreach ($rows as $i => $r) {
            $got = json_decode(json_encode(MomentStory::of($r['tick'], $r['seed']), JSON_UNESCAPED_UNICODE), true);
            $this->assertSame($r['story'], $got, "minute {$r['tick']['tick']} of match {$r['seed']} (row $i)");
        }
    }

    public function test_the_other_sides_instructions_are_not_named(): void
    {
        $tick = ['tick' => 30, 'minute' => [30, 0], 'score' => ['home' => 0, 'away' => 0], 'voice' => null, 'moment' => ['kind' => 'coach'],
            'events' => [['type' => 'action', 'team' => 'away', 'action' => ['type' => 'tactics']]]];
        $story = MomentStory::of($tick, 7);
        $this->assertSame('تعليمات جديدة', $story['sub']);
        $mine = MomentStory::of(['events' => [['type' => 'action', 'team' => 'away', 'action' => ['type' => 'tactics', 'tactics' => ['pressing' => 3, 'tempo' => 2]]]]] + $tick, 7);
        $this->assertSame(['t' => 'تعليمات: {v0}', 'v' => [['j' => ['الضغط', 'الإيقاع'], 'by' => ' و']]], $mine['sub']);
    }

    public function test_a_minute_without_its_moment_has_no_story(): void
    {
        $this->assertArrayNotHasKey('story', MomentStory::attach(['tick' => 3, 'minute' => [3, 0], 'events' => []], 1));
    }
}
