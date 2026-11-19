<?php

namespace Tests\Feature;

use App\Catalog\ProductCatalog;
use Tests\Fakes\ArrayProductCatalog;
use Tests\TestCase;

class AnswersTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->app->instance(ProductCatalog::class, new ArrayProductCatalog([
            ['id' => 1, 'name' => 'Kit', 'price' => 45000, 'stock' => 10],
            ['id' => 2, 'name' => 'Wheels', 'price' => 6000, 'stock' => 0],
        ]));
    }

    public function test_exercise_2_stock(): void
    {
        $this->getJson('/api/products/2/stock')
            ->assertOk()
            ->assertExactJson(['data' => ['id' => 2, 'stock' => 0, 'in_stock' => false]]);
    }

    public function test_exercise_3_price_range(): void
    {
        $this->getJson('/api/products?min_price=5000&max_price=10000')->assertJsonCount(1, 'data');
        $this->getJson('/api/products?max_price=7000')->assertJsonCount(1, 'data');
        $this->getJson('/api/products?min_price=9000&max_price=100')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['max_price']);
    }

    public function test_exercise_4_the_fake_is_used(): void
    {
        $this->getJson('/api/products')->assertJsonPath('data.0.name', 'Kit');
    }

    public function test_exercise_5_json_only(): void
    {
        $this->post('/api/products', ['name' => 'Form', 'price' => 100])->assertStatus(415);
        $this->call('POST', '/api/products', [], [], [], ['CONTENT_TYPE' => 'application/json'], '{}')
            ->assertUnprocessable()
            ->assertHeader('Content-Type', 'application/json');
    }
}
