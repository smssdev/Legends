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
            'name.required' => 'أعطِ المنتج اسماً.',
            'name.max' => 'الاسم :max حرفاً على الأكثر.',
            'price.integer' => 'السعر عدد صحيح من القروش.',
            'price.min' => 'يجب أن يكون السعر أكبر من 0.',
            'stock.min' => 'لا يجوز أن يكون المخزون سالباً.',
        ];
    }
}
