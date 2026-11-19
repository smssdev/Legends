<?php

namespace Tests\Feature;

use Database\Seeders\ProductSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AnswersTest extends TestCase
{
    use RefreshDatabase;

    protected $seeder = ProductSeeder::class;

    public function test_exercise_3_search(): void
    {
        $page = $this->getJson('/api/v1/products?q=سي&limit=1')->assertOk();
        $this->assertCount(1, $page->json('data'));
        $this->getJson($page->json('links.next'))->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/products?q=x')->assertStatus(422);
    }

    public function test_exercise_5_keys_belong_to_a_client_and_expire(): void
    {
        $order = ['items' => [['product_id' => 1, 'quantity' => 1]]];
        $a = ['Idempotency-Key' => 'same-key-001', 'X-Client-Id' => 'a'];
        $b = ['Idempotency-Key' => 'same-key-001', 'X-Client-Id' => 'b'];

        $first = $this->postJson('/api/v1/orders', $order, $a)->json('data.id');
        $other = $this->postJson('/api/v1/orders', $order, $b)->json('data.id');
        $this->assertNotSame($first, $other);

        $this->travel(25)->hours();
        $later = $this->postJson('/api/v1/orders', $order, $a)->assertCreated();
        $later->assertHeaderMissing('Idempotent-Replayed');
    }
}
