<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Catalog\ProductCatalog;
use App\Http\Requests\StoreProductRequest;
use App\Http\Requests\UpdateProductRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class ProductController extends Controller
{
    // تبني الحاوية المتحكم وتمرر إليه كتالوجاً
    public function __construct(private readonly ProductCatalog $catalog) {}

    public function index(Request $request): JsonResponse
    {
        $max = $request->integer('max_price', PHP_INT_MAX);
        $products = array_filter(
            $this->catalog->all(),
            fn (array $p) => $p['price'] <= $max,
        );

        return $this->json(['data' => array_values($products)]);
    }

    public function show(int $product): JsonResponse
    {
        return $this->json(['data' => $this->findOrFail($product)]);
    }

    public function store(StoreProductRequest $request): JsonResponse
    {
        // الحقول المفحوصة وحدها، ولا شيء آخر مما أرسله العميل
        $product = $this->catalog->create($request->validated());

        return $this
            ->json(['data' => $product], 201)
            ->header('Location', route('products.show', $product['id']));
    }

    public function update(UpdateProductRequest $request, int $product): JsonResponse
    {
        $this->findOrFail($product);
        $changed = $this->catalog->update($product, $request->validated());

        return $this->json(['data' => $changed]);
    }

    public function destroy(int $product): Response
    {
        $this->findOrFail($product);
        $this->catalog->delete($product);

        return response()->noContent();
    }

    // بدون هذا الخيار يكتب Laravel كل حرف غير إنجليزي بالشكل \u0643 وأمثاله.
    private function json(array $data, int $status = 200): JsonResponse
    {
        return response()->json($data, $status, [], JSON_UNESCAPED_UNICODE);
    }

    private function findOrFail(int $id): array
    {
        $product = $this->catalog->find($id);
        if ($product === null) {
            abort(404, __('لا يوجد منتج رقمه :id.', ['id' => $id]));
        }

        return $product;
    }
}
