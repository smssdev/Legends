<?php

namespace Tests\Feature;

use Database\Seeders\ProductSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ShopApiTest extends TestCase
{
    use RefreshDatabase;

    protected $seeder = ProductSeeder::class;

    public function test_it_walks_every_page_without_repeats_or_gaps(): void
    {
        $seen = [];
        $url = '/api/v1/products?limit=5';
        while ($url !== null) {
            $page = $this->getJson($url)->assertOk();
            $seen = [...$seen, ...array_column($page->json('data'), 'id')];
            $url = $page->json('links.next');
        }
        $this->assertSame(range(1, 12), $seen);
    }

    public function test_it_sorts_by_price_highest_first(): void
    {
        $this->getJson('/api/v1/products?sort=-price&limit=3')
            ->assertJsonPath('data.*.price.amount', [45000, 30000, 21000]);
    }

    public function test_it_replays_an_order_instead_of_creating_it_twice(): void
    {
        $order = ['items' => [['product_id' => 1, 'quantity' => 2]]];
        $headers = ['Idempotency-Key' => 'test-key-0001'];
        $first = $this->postJson('/api/v1/orders', $order, $headers)->assertCreated();
        $second = $this->postJson('/api/v1/orders', $order, $headers);

        $second->assertHeader('Idempotent-Replayed', 'true');
        $this->assertSame($first->json(), $second->json());
        $this->getJson('/api/v1/products/1')->assertJsonPath('data.stock', 8);
    }

    public function test_it_refuses_a_stale_update(): void
    {
        $patch = fn () => $this->patchJson(
            '/api/v1/products/2', ['stock' => 3], ['If-Match' => '"1"']);
        $patch()->assertOk()->assertHeader('ETag', '"2"');
        $patch()->assertStatus(412);
    }

    public function test_it_answers_422_problems_with_every_invalid_field(): void
    {
        $order = ['items' => [['product_id' => 99, 'quantity' => 0]]];
        $this->postJson('/api/v1/orders', $order, ['Idempotency-Key' => 'test-key-0002'])
            ->assertStatus(422)
            ->assertHeader('Content-Type', 'application/problem+json')
            ->assertJsonCount(2, 'errors');
    }
}
