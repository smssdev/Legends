<?php

namespace App\Orders\Infrastructure;

use App\Orders\Domain\OrderRules;
use App\Orders\Domain\OutOfStock;
use App\Orders\Domain\PlacedOrder;
use App\Orders\Domain\UnknownProduct;
use App\Orders\Ports\OrderStore;
use DateTimeImmutable;
use Illuminate\Support\Facades\DB;

// محوّل: المنفذ OrderStore، مطبَّقاً بباني الاستعلامات في Laravel
final class QueryBuilderOrderStore implements OrderStore
{
    public function place(string $email, array $items, DateTimeImmutable $placedAt): PlacedOrder
    {
        return DB::transaction(function () use ($email, $items, $placedAt) {
            $lines = [];
            foreach ($items as ['product_id' => $id, 'quantity' => $quantity]) {
                $taken = DB::table('products')->where('id', $id)
                    ->where('stock', '>=', $quantity)->decrement('stock', $quantity);
                if ($taken === 0) {
                    throw DB::table('products')->where('id', $id)->exists()
                        ? new OutOfStock('المخزون لا يكفي')
                        : new UnknownProduct('منتج مجهول');
                }
                $price = DB::table('products')->where('id', $id)->value('price');
                $lines[] = ['product_id' => $id, 'quantity' => $quantity, 'price' => $price];
            }
            $total = OrderRules::total($lines);
            $orderId = DB::table('orders')->insertGetId(
                ['email' => $email, 'total' => $total, 'placed_at' => $placedAt],
            );
            DB::table('order_items')->insert(
                array_map(fn ($line) => ['order_id' => $orderId] + $line, $lines),
            );

            return new PlacedOrder($orderId, $email, $total);
        });
    }
}
