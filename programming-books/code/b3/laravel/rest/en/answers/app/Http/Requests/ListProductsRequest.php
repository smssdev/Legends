<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ListProductsRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'limit' => ['sometimes', 'integer', 'between:1,50'],
            'sort' => ['sometimes', 'in:id,price,-price,name'],
            'min_price' => ['sometimes', 'integer', 'min:0'],
            'max_price' => ['sometimes', 'integer', 'min:0'],
            'cursor' => ['sometimes', 'string'],
            'q' => ['sometimes', 'string', 'min:2', 'max:50'],
        ];
    }

    public function messages(): array
    {
        return [
            'limit.*' => 'A page has 1 to 50 items.',
            'sort.in' => 'Sort by id, price, -price or name.',
        ];
    }
}
