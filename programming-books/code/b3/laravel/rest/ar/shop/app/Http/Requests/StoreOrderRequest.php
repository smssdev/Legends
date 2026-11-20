<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreOrderRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'items' => ['required', 'array', 'between:1,20'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'between:1,99'],
        ];
    }

    public function messages(): array
    {
        return [
            'items.*' => 'يحتاج الطلب من 1 إلى 20 عنصراً.',
            'items.*.product_id.*' => 'لا يوجد منتج رقمه :input.',
            'items.*.quantity.*' => 'الكمية عدد صحيح من 1 إلى 99.',
        ];
    }
}
