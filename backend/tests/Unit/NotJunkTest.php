<?php

namespace Tests\Unit;

use App\Rules\NotJunk;
use PHPUnit\Framework\TestCase;

/** [X61] A test's name never reaches the players: the words and one key held down are refused, real names pass. */
class NotJunkTest extends TestCase
{
    public function test_test_names_are_refused_and_real_names_pass(): void
    {
        foreach (['test', 'Tesst', ' تست ', 'تجربة', 'Hhh', 'ytkregekgek', 'asdf!', '...aaaa'] as $junk) {
            $this->assertTrue(NotJunk::junk($junk), $junk);
        }
        foreach (['دوري الأصدقاء', 'Test Cup 2026', 'LALIGA EA SPORTS #73VYZAL7', 'Al Ahly', 'كأس الجمعة', 'Liga 1'] as $real) {
            $this->assertFalse(NotJunk::junk($real), $real);
        }
    }
}
