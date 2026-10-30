<?php

namespace Tests\Unit;

use App\Support\Nation;
use PHPUnit\Framework\TestCase;

/** [X61] A country in capitals reads like the others, and both spellings share one key (scout, chemistry). */
class NationTest extends TestCase
{
    public function test_capitals_read_as_a_title_and_both_spellings_share_a_key(): void
    {
        $this->assertSame('Egypt', Nation::name('EGYPT'));
        $this->assertSame('Saudi Arabia', Nation::name('SAUDI ARABIA'));
        $this->assertSame('Côte d\'Ivoire', Nation::name('Côte d\'Ivoire'));
        $this->assertSame('Korea Republic', Nation::name('Korea Republic'));
        $this->assertNull(Nation::name(null));
        $this->assertSame(Nation::key('IRAQ'), Nation::key('Iraq'));
    }
}
