<?php

namespace App\Orders\Http;

use App\Orders\Actions\PlaceOrder;
use App\Orders\Domain\OrderError;
use App\Orders\Domain\OutOfStock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

// محوّل HTTP: مدخلات مُتحقق منها إلى الداخل، ورد أو خطأ إلى الخارج
final class PlaceOrderController
{
    public function __invoke(Request $request, PlaceOrder $placeOrder): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'items' => ['required', 'array', 'min:1', 'max:20'],
            'items.*.product_id' => ['required', 'integer'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ]);
        try {
            $order = $placeOrder($data['email'], $data['items'], now()->toDateTimeImmutable());
        } catch (OrderError $error) {
            $status = $error instanceof OutOfStock ? 409 : 422;

            return response()->json(['title' => $error->getMessage(), 'status' => $status], $status);
        }

        return response()->json(['id' => $order->id, 'total' => $order->total], 201);
    }
}
