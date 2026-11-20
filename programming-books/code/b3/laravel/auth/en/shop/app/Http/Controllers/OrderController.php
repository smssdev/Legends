<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(
            $request->user()->orders()->orderBy('id')->get(['id', 'total']),
        );
    }

    public function show(Order $order): JsonResponse
    {
        Gate::authorize('view', $order);

        return response()->json($order->only('id', 'user_id', 'total'));
    }

    public function users(): JsonResponse
    {
        return response()->json(User::orderBy('id')->get(['id', 'email', 'role']));
    }
}
