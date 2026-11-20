<?php

namespace Tests\Feature;

use App\Catalog\JsonProductCatalog;
use App\Catalog\ProductCatalog;
use Tests\TestCase;

class ProductApiTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        // لكل اختبار ملفه الفارغ، فلا تتشارك الاختبارات البيانات أبداً
        $file = tempnam(sys_get_temp_dir(), 'catalog');
        unlink($file);
        $this->app->instance(ProductCatalog::class, new JsonProductCatalog($file));
    }

    public function test_it_lists_the_products(): void
    {
        $this->getJson('/api/products')
            ->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.price', 45000);
    }

    public function test_it_creates_a_product_and_says_where_it_is(): void
    {
        $this->postJson('/api/products', ['name' => 'كابل USB', 'price' => 2500])
            ->assertCreated()
            ->assertHeader('Location', url('/api/products/4'))
            ->assertJsonPath('data.stock', 0);

        $this->getJson('/api/products/4')->assertOk();
    }

    public function test_it_refuses_an_invalid_product_with_every_error(): void
    {
        $this->postJson('/api/products', ['price' => 0, 'stock' => -1])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'price', 'stock']);
    }
}
