<?php

namespace Database\Factories;

use App\Models\Product;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Product>
 */
class ProductFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->words(2, true),
            'price' => fake()->numberBetween(100, 50000),
            'stock' => fake()->numberBetween(0, 20),
        ];
    }
}
