<?php

declare(strict_types=1);

namespace App\Catalog;

// ما تحتاجه المتحكمات من الكتالوج، لا طريقة تخزينه للمنتجات.
interface ProductCatalog
{
    /** @return list<array{id: int, name: string, price: int, stock: int}> */
    public function all(): array;

    /** @return array{id: int, name: string, price: int, stock: int}|null */
    public function find(int $id): ?array;

    /** @param array{name: string, price: int, stock?: int} $data */
    public function create(array $data): array;

    public function update(int $id, array $data): ?array;

    public function delete(int $id): bool;
}
