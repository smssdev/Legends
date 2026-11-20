<?php

declare(strict_types=1);

namespace Tests\Fakes;

use App\Catalog\ProductCatalog;

// The same contract as the real catalog, kept in memory: fast, and nothing to clean up.
final class ArrayProductCatalog implements ProductCatalog
{
    public function __construct(private array $products = []) {}

    public function all(): array
    {
        return $this->products;
    }

    public function find(int $id): ?array
    {
        return array_find($this->products, fn (array $p) => $p['id'] === $id);
    }

    public function create(array $data): array
    {
        $product = ['id' => count($this->products) + 1, 'stock' => 0, ...$data];
        $this->products[] = $product;
        return $product;
    }

    public function update(int $id, array $data): ?array
    {
        foreach ($this->products as $i => $product) {
            if ($product['id'] === $id) {
                return $this->products[$i] = [...$product, ...$data];
            }
        }
        return null;
    }

    public function delete(int $id): bool
    {
        $before = count($this->products);
        $this->products = array_values(array_filter($this->products, fn ($p) => $p['id'] !== $id));
        return count($this->products) < $before;
    }
}
