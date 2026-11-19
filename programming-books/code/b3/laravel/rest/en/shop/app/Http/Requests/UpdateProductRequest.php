<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProductRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:80'],
            'price' => ['sometimes', 'integer', 'min:1'],
            'stock' => ['sometimes', 'integer', 'min:0'],
        ];
    }

    public function after(): array
    {
        return [function ($validator) {
            if ($this->safe()->collect()->isEmpty()) {
                $message = 'Send at least one field to change.';
                $validator->errors()->add('fields', $message);
            }
        }];
    }

    public function messages(): array
    {
        return [
            'price.*' => 'The price must be above 0.',
            'stock.*' => 'Stock cannot be negative.',
        ];
    }
}
