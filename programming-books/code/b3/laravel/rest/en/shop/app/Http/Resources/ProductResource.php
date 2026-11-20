<?php

namespace App\Http\Resources;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Product */
class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // version is internal: the client sees it only as the ETag
        return [
            'id' => $this->id,
            'name' => $this->name,
            'price' => Money::of($this->price),
            'stock' => $this->stock,
            'created_at' => $this->created_at->toIso8601ZuluString(),
        ];
    }
}
