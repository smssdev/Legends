<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Problems;
use App\Http\Requests\ListProductsRequest;
use App\Http\Requests\UpdateProductRequest;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

final class ProductController extends Controller
{
    public function index(ListProductsRequest $request): AnonymousResourceCollection
    {
        $sort = $request->validated('sort', 'id');
        $direction = str_starts_with($sort, '-') ? 'desc' : 'asc';
        $min = $request->validated('min_price');
        $max = $request->validated('max_price');

        $products = Product::query()
            ->when($min !== null, fn ($query) => $query->where('price', '>=', $min))
            ->when($max !== null, fn ($query) => $query->where('price', '<=', $max))
            ->when($request->validated('q'), fn ($query, $q) => $query->whereLike('name', "%$q%"))
            ->orderBy(ltrim($sort, '-'), $direction)
            // ترتيب كامل: السعر المتساوي يحسمه الرقم
            ->orderBy('id', $direction)
            ->cursorPaginate((int) $request->validated('limit', 5))
            ->withQueryString();

        return ProductResource::collection($products);
    }

    public function show(Request $request, Product $product): JsonResponse
    {
        $response = ProductResource::make($product)->response();
        $response->setEtag((string) $product->version);
        // 304 and no body when If-None-Match matches
        $response->isNotModified($request);

        return $response;
    }

    public function update(
        UpdateProductRequest $request,
        Product $product,
    ): JsonResponse {
        $ifMatch = $request->header('If-Match');
        if ($ifMatch === null) {
            throw Problems::needIfMatch();
        }
        // جملة واحدة: غيّره فقط إن كان الإصدار ما زال الذي قرأه العميل
        $changed = Product::whereKey($product->id)
            ->where('version', (int) trim($ifMatch, '"'))
            ->update([...$request->validated(), 'version' => DB::raw('version + 1')]);
        if ($changed === 0) {
            throw Problems::stale();
        }

        return $this->show($request, $product->refresh());
    }
}
