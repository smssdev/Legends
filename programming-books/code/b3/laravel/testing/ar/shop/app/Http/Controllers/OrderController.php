<?php

namespace App\Http\Controllers;

use App\Jobs\SendOrderConfirmation;
use App\Support\Pricing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'product_id' => ['required', 'integer'],
            'quantity' => ['required', 'integer', 'min:1', 'max:99'],
            'code' => ['nullable', 'string'],
        ]);
        $order = DB::transaction(function () use ($data) {
            $taken = DB::table('products')->where('id', $data['product_id'])
                ->where('stock', '>=', $data['quantity'])->decrement('stock', $data['quantity']);
            if ($taken === 0) {
                return null;
            }
            $price = DB::table('products')->where('id', $data['product_id'])->value('price');
            $sum = Pricing::total([['price' => $price, 'quantity' => $data['quantity']]], $data['code'] ?? null);
            $id = DB::table('orders')->insertGetId(['email' => $data['email'], 'total' => $sum['total']]);

            return ['id' => $id, 'total' => $sum['total']];
        });
        abort_if($order === null, 409, 'المخزون لا يكفي');
        SendOrderConfirmation::dispatch($order['id'])->afterCommit();

        return response()->json($order, 201);
    }
}
