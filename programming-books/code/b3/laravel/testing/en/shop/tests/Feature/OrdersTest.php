<?php

use App\Jobs\SendOrderConfirmation;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;

beforeEach(function () {
    DB::table('products')->insert(['id' => 1, 'name' => 'Kit', 'price' => 45000, 'stock' => 3]);
    // the queue is faked: jobs are recorded instead of being pushed to Redis
    Queue::fake();
});

function order(int $quantity)
{
    return test()->postJson('/api/orders', [
        'email' => 'sara@example.com', 'product_id' => 1, 'quantity' => $quantity, 'code' => 'SAVE10',
    ]);
}

it('creates an order and queues one confirmation', function () {
    order(2)->assertCreated()->assertExactJson(['id' => 1, 'total' => 92340]);

    expect(DB::table('products')->value('stock'))->toBe(1);
    Queue::assertPushed(SendOrderConfirmation::class, fn ($job) => $job->orderId === 1);
    Queue::assertPushed(SendOrderConfirmation::class, 1);
});

it('refuses an order larger than the stock, and changes nothing', function () {
    order(4)->assertConflict();

    expect(DB::table('orders')->count())->toBe(0);
    expect(DB::table('products')->value('stock'))->toBe(3);
    Queue::assertNothingPushed();
});

it('refuses a body without a quantity', function () {
    $this->postJson('/api/orders', ['email' => 'sara@example.com', 'product_id' => 1])
        ->assertUnprocessable()
        ->assertJsonValidationErrors('quantity');
});
