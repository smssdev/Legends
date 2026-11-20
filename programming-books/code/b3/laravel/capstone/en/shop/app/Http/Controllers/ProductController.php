<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $limit = $request->validate([
            'limit' => ['integer', 'min:1', 'max:50'],
        ])['limit'] ?? 20;
        // Laravel's cursor pages: the cursor holds the last row's price and id
        $page = Product::query()
            ->select('id', 'name', 'price', 'stock')
            ->orderBy('price')
            ->orderBy('id')
            ->cursorPaginate($limit);

        return response()->json([
            'data' => $page->items(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }
}
