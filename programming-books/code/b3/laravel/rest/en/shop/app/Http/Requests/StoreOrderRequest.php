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
            'items.*' => 'An order needs 1 to 20 items.',
            'items.*.product_id.*' => 'There is no product :input.',
            'items.*.quantity.*' => 'A quantity is a whole number from 1 to 99.',
        ];
    }
}
