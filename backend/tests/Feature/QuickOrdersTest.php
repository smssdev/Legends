<?php

namespace Tests\Feature;

use Tests\TestCase;

/** [Sprint 57 B3] The quick orders come from config/game.php, the same for the web and the app. */
class QuickOrdersTest extends TestCase
{
    public function test_the_quick_orders_are_the_configs(): void
    {
        $r = $this->getJson('/api/v1/data/quick-orders')->assertOk();
        $this->assertSame(config('game.quick_orders'), $r->json('orders'));
        $this->assertCount(6, $r->json('orders'));
        $this->assertSame(['pressing' => 85, 'trap' => 1], $r->json('orders.2.tactics'));
        $this->assertNull($r->json('orders.5.tactics'));
    }
}
