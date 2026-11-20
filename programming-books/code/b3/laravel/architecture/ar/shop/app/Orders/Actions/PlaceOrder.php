<?php

namespace App\Orders\Actions;

use App\Orders\Domain\OrderRules;
use App\Orders\Domain\PlacedOrder;
use App\Orders\Ports\Mailer;
use App\Orders\Ports\OrderStore;
use DateTimeImmutable;

// الفعل: شيء واحد يفعله المتجر، من البداية إلى النهاية، عبر منافذه
final readonly class PlaceOrder
{
    public function __construct(private OrderStore $store, private Mailer $mailer) {}

    /** @param list<array{product_id: int, quantity: int}> $items */
    public function __invoke(string $email, array $items, DateTimeImmutable $now): PlacedOrder
    {
        OrderRules::checkQuantities($items);
        $order = $this->store->place($email, $items, $now);
        // البريد بعد حفظ الطلب، لا داخل معاملته أبداً
        $this->mailer->send($email, "Order {$order->id}: ".($order->total / 100).' EGP');

        return $order;
    }
}
