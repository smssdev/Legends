<?php

declare(strict_types=1);

namespace App\Catalog;

// المنتجات في ملف JSON كما في الفصل 1، ويستبدل الفصل 6 هذا الصنف بقاعدة بيانات.
final class JsonProductCatalog implements ProductCatalog
{
    public function __construct(private readonly string $path) {}

    public function all(): array
    {
        return $this->read()['products'];
    }

    public function find(int $id): ?array
    {
        return array_find($this->all(), fn (array $p) => $p['id'] === $id);
    }

    public function create(array $data): array
    {
        return $this->change(function (array $store) use ($data) {
            $product = ['id' => $store['next_id'], 'stock' => 0, ...$data];
            $store['products'][] = $product;
            $store['next_id']++;

            return [$store, $product];
        });
    }

    public function update(int $id, array $data): ?array
    {
        return $this->change(function (array $store) use ($id, $data) {
            foreach ($store['products'] as $i => $product) {
                if ($product['id'] === $id) {
                    $store['products'][$i] = [...$product, ...$data];

                    return [$store, $store['products'][$i]];
                }
            }

            return [$store, null];
        });
    }

    public function delete(int $id): bool
    {
        return $this->change(function (array $store) use ($id) {
            $left = array_filter(
                $store['products'],
                fn (array $p) => $p['id'] !== $id,
            );
            $deleted = count($left) < count($store['products']);
            $store['products'] = array_values($left);

            return [$store, $deleted];
        });
    }

    private function read(): array
    {
        if (! is_file($this->path)) {
            return self::seed();
        }

        return json_decode((string) file_get_contents($this->path), true);
    }

    private function change(callable $edit): mixed
    {
        $file = fopen($this->path, 'c+');
        // القفل يجعل الطلب الثاني ينتظر بينما يكتب الأول
        flock($file, LOCK_EX);
        $text = stream_get_contents($file);
        [$store, $result] = $edit($text ? json_decode($text, true) : self::seed());
        ftruncate($file, 0);
        rewind($file);
        fwrite($file, json_encode($store, JSON_UNESCAPED_UNICODE));
        flock($file, LOCK_UN);
        fclose($file);

        return $result;
    }

    private static function seed(): array
    {
        return ['next_id' => 4, 'products' => [
            ['id' => 1, 'name' => 'عدة الروبوت', 'price' => 45000, 'stock' => 10],
            ['id' => 2, 'name' => 'عجلات احتياطية', 'price' => 6000, 'stock' => 25],
            ['id' => 3, 'name' => 'حزمة بطارية', 'price' => 12500, 'stock' => 0],
        ]];
    }
}
