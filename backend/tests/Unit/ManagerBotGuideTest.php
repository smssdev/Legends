<?php

namespace Tests\Unit;

use App\Assistant\Assistant;
use App\Assistant\Guide;
use App\Assistant\Search;
use Tests\TestCase;

/** [Sprint 22 B1, B2] The game's guide and its smart search. */
class ManagerBotGuideTest extends TestCase
{
    public function test_every_topic_is_whole_in_both_languages_and_every_page_has_questions(): void
    {
        $ar = Guide::topics('ar');
        $en = Guide::topics('en');
        $this->assertSame(array_column($ar, 'id'), array_column($en, 'id'));
        $this->assertSame(count($ar), count(array_unique(array_column($ar, 'id'))));
        foreach ($ar as $i => $t) {
            $this->assertMatchesRegularExpression('/\p{Arabic}/u', $t['q'].$t['a'], $t['id']);
            $this->assertDoesNotMatchRegularExpression('/\p{Arabic}/u', $en[$i]['q'].$en[$i]['a'], $t['id']);
            $this->assertNotSame('', trim($en[$i]['a']), $t['id']);
            $this->assertTrue($t['go'] === null || in_array($t['go'], Guide::GO, true), $t['id']);
        }
        foreach (Guide::PAGES as $page) {
            $this->assertNotEmpty(Guide::quick($page, 'ar'), $page);
            $this->assertCount(count(Guide::quick($page, 'ar')), Guide::quick($page, 'en'), $page);
        }
        $this->assertSame('home', Guide::page('nowhere'));
        $this->assertSame('newspaper', Guide::page('league-newspaper'));
    }

    public function test_the_numbers_come_from_the_config(): void
    {
        config(['game.friendlies.per_day' => 7, 'game.stadium.part_hours' => 11]);
        $this->assertStringContainsString('لك 7 في اليوم', Guide::find('friendlies', 'ar')['a']);
        $this->assertStringContainsString('11 hours', Guide::find('stadium_plan', 'en')['a']);
    }

    public function test_the_search_finds_the_coachs_own_spelling(): void
    {
        $find = fn (string $q, string $l = 'ar') => Search::find($q, Guide::topics($l))['topic']['id'] ?? null;
        $this->assertSame('trap', $find('يعني ايه المصيده'));
        $this->assertSame('trap', $find('مَصْيَدة التسلُّل'));
        $this->assertSame('lineup_edit', $find('ازاي اعدل التشكيله'));
        $this->assertSame('spy', $find('الجاسوس بيعمل ايه'));
        $this->assertSame('debt', $find('رصيدي بالسالب'));
        $this->assertSame('scout', $find('what does the scout do', 'en'));
        $this->assertSame('chemistry', $find('chemestry', 'en'));
        $this->assertNull($find('ما'));
        $this->assertSame(['تشكيله', 'مصيده'], Search::tokens('التشكيلة والمصيدة'));
    }

    public function test_the_ais_page_tag_opens_only_a_page_of_the_game(): void
    {
        $this->assertSame(['درّب اللياقة.', 'training'], Assistant::link('درّب اللياقة. [go:training]'));
        $this->assertSame(['جواب', null], Assistant::link('جواب [go:admin]'));
        $this->assertSame(['جواب', null], Assistant::link('جواب'));
    }
}
