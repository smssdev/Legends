<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Problems;
use App\Http\Requests\StoreOrderRequest;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

final class OrderController extends Controller
{
    public function store(StoreOrderRequest $request): JsonResponse
    {
        // anything thrown here undoes the whole transaction, stock included
        $order = DB::transaction(function () use ($request) {
            $items = [];
            foreach ($request->validated('items') as $line) {
                ['product_id' => $id, 'quantity' => $quantity] = $line;
                // take stock only if there is enough: two orders never get the last one
                $taken = Product::whereKey($id)
                    ->where('stock', '>=', $quantity)
                    ->decrement('stock', $quantity, [
                        'version' => DB::raw('version + 1'),
                    ]);
                $product = Product::findOrFail($id);
                if ($taken === 0) {
                    throw Problems::outOfStock($id, $product->stock);
                }
                // the price comes from the database, never from the client
                $items[] = [
                    'product_id' => $id,
                    'quantity' => $quantity,
                    'price' => $product->price,
                ];
            }
            $total = array_sum(array_map(
                fn ($item) => $item['price'] * $item['quantity'],
                $items,
            ));
            $order = Order::create(['status' => 'pending', 'total' => $total]);
            $order->items()->createMany($items);

            return $order;
        });

        return OrderResource::make($order->load('items'))
            ->response()
            ->setStatusCode(201)
            ->header('Location', route('orders.show', $order));
    }

    public function show(Order $order): OrderResource
    {
        return OrderResource::make($order->load('items'));
    }

    public function cancel(Order $order): OrderResource
    {
        if ($order->status !== 'pending') {
            throw Problems::cannotCancel($order->id, $order->status);
        }
        DB::transaction(function () use ($order) {
            $order->update(['status' => 'cancelled']);
            foreach ($order->items as $item) {
                Product::whereKey($item->product_id)
                    ->increment('stock', $item->quantity);
            }
        });

        return $this->show($order);
    }
}
