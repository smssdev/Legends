<?php

use App\Orders\Actions\PlaceOrder;
use App\Orders\Domain\OutOfStock;
use App\Orders\Domain\PlacedOrder;
use App\Orders\Domain\TooMany;
use App\Orders\Ports\Mailer;
use App\Orders\Ports\OrderStore;

// البدائل: المنافذ، مطبَّقة في الذاكرة لهذا الاختبار
function fakeMailer(): Mailer
{
    return new class implements Mailer
    {
        public array $sent = [];

        public function send(string $to, string $subject): void
        {
            $this->sent[] = $to;
        }
    };
}

function fakeStore(Closure $place): OrderStore
{
    return new class($place) implements OrderStore
    {
        public function __construct(private Closure $place) {}

        public function place(string $email, array $items, DateTimeImmutable $placedAt): PlacedOrder
        {
            return ($this->place)($email, $items, $placedAt);
        }
    };
}

$now = new DateTimeImmutable('2026-11-20 10:00:00');

it('places an order, saves it and sends one email', function () use ($now) {
    $mailer = fakeMailer();
    $store = fakeStore(fn ($email) => new PlacedOrder(7, $email, 12000));
    $order = (new PlaceOrder($store, $mailer))('sara@example.com', [['product_id' => 2, 'quantity' => 2]], $now);

    expect($order->total)->toBe(12000)
        ->and($mailer->sent)->toBe(['sara@example.com']);
});

it('refuses more than 10 of one product, before touching the store', function () use ($now) {
    $store = fakeStore(fn () => throw new LogicException('the store must not be called'));
    (new PlaceOrder($store, fakeMailer()))('a@b.c', [['product_id' => 1, 'quantity' => 11]], $now);
})->throws(TooMany::class);

it('sends no email when the store reports too little stock', function () use ($now) {
    $mailer = fakeMailer();
    $store = fakeStore(fn () => throw new OutOfStock('no'));

    expect(fn () => (new PlaceOrder($store, $mailer))('a@b.c', [['product_id' => 1, 'quantity' => 9]], $now))
        ->toThrow(OutOfStock::class)
        ->and($mailer->sent)->toBe([]);
});
