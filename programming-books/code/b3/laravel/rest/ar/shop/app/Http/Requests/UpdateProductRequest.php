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
                $message = 'أرسل حقلاً واحداً على الأقل لتغييره.';
                $validator->errors()->add('fields', $message);
            }
        }];
    }

    public function messages(): array
    {
        return [
            'price.*' => 'يجب أن يكون السعر أكبر من 0.',
            'stock.*' => 'لا يجوز أن يكون المخزون سالباً.',
        ];
    }
}
