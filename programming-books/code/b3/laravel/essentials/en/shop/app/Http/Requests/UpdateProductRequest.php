<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class UpdateProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:80'],
            'price' => ['sometimes', 'integer', 'min:1'],
            'stock' => ['sometimes', 'integer', 'min:0'],
            'fields' => ['prohibited'],
        ];
    }

    // Runs after the rules: a body with none of the fields changes nothing.
    public function after(): array
    {
        return [
            function ($validator) {
                if ($this->safe()->collect()->isEmpty()) {
                    $message = __('Send at least one field to change.');
                    $validator->errors()->add('fields', $message);
                }
            },
        ];
    }

    public function messages(): array
    {
        return (new StoreProductRequest)->messages();
    }
}
