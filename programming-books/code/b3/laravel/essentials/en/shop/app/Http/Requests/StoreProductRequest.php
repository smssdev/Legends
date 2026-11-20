<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class StoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Chapter 9 decides who may add products
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:80'],
            'price' => ['required', 'integer', 'min:1'],
            'stock' => ['sometimes', 'integer', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Give the product a name.',
            'name.max' => 'A name has at most :max characters.',
            'price.integer' => 'The price is a whole number of piastres.',
            'price.min' => 'The price must be above 0.',
            'stock.min' => 'Stock cannot be negative.',
        ];
    }
}
