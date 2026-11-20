<?php

use App\Models\Product;
use Illuminate\Foundation\Testing\DatabaseTruncation;
use Illuminate\Support\Facades\DB;

// تُرحَّل shop_test مرة، ثم يُفرَّغ كل جدول قبل كل اختبار
pest()->use(DatabaseTruncation::class);

beforeEach(fn () => $this->seed());

function signIn(): array
{
    $user = ['email' => 'sara@example.com', 'name' => 'Sara', 'password' => 'a long password'];
    test()->postJson('/api/auth/register', $user);
    $token = test()->postJson('/api/auth/login', $user)->json('token');

    return ['Authorization' => "Bearer $token"];
}

function order(array $headers, string $key, array $items)
{
    return test()->postJson('/api/orders', ['items' => $items], [...$headers, 'Idempotency-Key' => $key]);
}

test('places an order once, however many times the same key is sent', function () {
    $auth = signIn();
    $items = [['product_id' => 2, 'quantity' => 3]];
    $first = order($auth, 'key-0001', $items)->assertCreated();
    order($auth, 'key-0001', $items)->assertOk()->assertJsonPath('id', $first->json('id'));
    expect(Product::find(2)->stock)->toBe(47)
        ->and(DB::table('jobs')->count())->toBe(1);
});

test('refuses a key reused with another body', function () {
    $auth = signIn();
    order($auth, 'key-0002', [['product_id' => 2, 'quantity' => 1]]);
    order($auth, 'key-0002', [['product_id' => 2, 'quantity' => 2]])->assertStatus(422);
});

test('takes no stock when one line is short', function () {
    $response = order(signIn(), 'key-0003', [
        ['product_id' => 2, 'quantity' => 1],
        ['product_id' => 1, 'quantity' => 6],
    ]);
    $response->assertConflict();
    expect(Product::find(2)->stock)->toBe(50)
        ->and(DB::table('orders')->count())->toBe(0)
        ->and(DB::table('jobs')->count())->toBe(0);
});

test('refuses an order without a token', function () {
    order([], 'key-0004', [['product_id' => 2, 'quantity' => 1]])
        ->assertUnauthorized()
        ->assertHeader('Content-Type', 'application/problem+json');
});

test('pages follow each other with no gaps and no repeats', function () {
    $seen = [];
    $url = '/api/products?limit=2';
    do {
        $page = $this->getJson($url)->json();
        $seen = [...$seen, ...array_column($page['data'], 'id')];
        $url = "/api/products?limit=2&cursor={$page['next_cursor']}";
    } while ($page['next_cursor']);
    expect($seen)->toBe([2, 4, 3, 5, 1]);
});
