<?php

namespace App\Http\Controllers;

use App\Http\Problem;
use App\Jobs\SendOrderEmail;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $items = $request->validate([
            'items' => ['required', 'array', 'min:1', 'max:20'],
            'items.*.product_id' => ['required', 'integer', 'min:1', 'distinct'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:10'],
        ])['items'];
        $key = Validator::validate(
            ['idempotency_key' => $request->header('Idempotency-Key')],
            ['idempotency_key' => ['required', 'string', 'min:8', 'max:100']],
        )['idempotency_key'];
        $user = $request->user();
        $hash = hash('sha256', json_encode($items));

        // all or nothing: the order, its lines, the stock and the job commit together
        [$order, $replayed] = DB::transaction(function () use ($user, $key, $hash, $items) {
            // the key is claimed first; ON CONFLICT DO NOTHING inserts nothing if it was used
            $claimed = DB::table('orders')->insertOrIgnore([
                'user_id' => $user->id, 'idempotency_key' => $key, 'request_hash' => $hash,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            $order = $user->orders()->where('idempotency_key', $key)->firstOrFail();
            if ($claimed === 0) {
                // the key was used before: return that order, unless the body is different
                if ($order->request_hash !== $hash) {
                    throw Problem::keyReused();
                }

                return [$order, true];
            }

            $total = 0;
            foreach ($items as ['product_id' => $id, 'quantity' => $quantity]) {
                // the stock is taken only if it is enough, in the same statement
                $taken = Product::whereKey($id)->where('stock', '>=', $quantity)
                    ->decrement('stock', $quantity);
                if ($taken === 0) {
                    $stock = Product::whereKey($id)->value('stock');
                    throw $stock === null
                        ? Problem::unknownProduct($id)
                        : Problem::outOfStock($id, $stock);
                }
                $price = Product::whereKey($id)->value('price');
                $order->items()->create(['product_id' => $id, 'quantity' => $quantity, 'price' => $price]);
                $total += $price * $quantity;
            }
            $order->update(['total' => $total]);
            // the database queue writes the job in this same transaction: an outbox, with no extra table
            SendOrderEmail::dispatch($order->id);

            return [$order, false];
        });

        return response()->json(self::present($order), $replayed ? 200 : 201,
            $replayed ? ['Idempotent-Replayed' => 'true'] : []);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        return response()->json(self::present($request->user()->orders()->findOrFail($id)));
    }

    private static function present(Order $order): array
    {
        $items = $order->items()->orderBy('product_id')->get(['product_id', 'quantity', 'price']);

        return ['id' => $order->id, 'total' => $order->total,
            'created_at' => $order->created_at, 'items' => $items];
    }
}
