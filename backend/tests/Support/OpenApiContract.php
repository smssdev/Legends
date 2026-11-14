<?php

namespace Tests\Support;

use Symfony\Component\Yaml\Yaml;

/**
 * [Sprint 66 T9] The contract (docs/api/openapi.yaml) against a real answer: what a route documents for its status,
 * checked the way the clients read it (the web's types and the app's generated models): every required field there,
 * each field of its documented type (null only where nullable), arrays item by item, $ref, allOf, oneOf and anyOf.
 * Fields the contract does not list are allowed (a client ignores them).
 */
final class OpenApiContract
{
    private static ?array $spec = null;

    public static function spec(): array
    {
        return self::$spec ??= Yaml::parseFile(__DIR__.'/../../../docs/api/openapi.yaml');
    }

    /** The paths the contract documents for this method. */
    public static function paths(string $method): array
    {
        return array_keys(array_filter(self::spec()['paths'], fn ($p) => isset($p[strtolower($method)])));
    }

    /**
     * Where the answer differs from the contract (empty when it matches). Null when the contract has no JSON schema
     * for this status (nothing to compare).
     *
     * @return list<string>|null
     */
    public static function check(string $method, string $path, int $status, mixed $body): ?array
    {
        $op = self::spec()['paths'][$path][strtolower($method)] ?? null;
        if (! $op) {
            return ["{$method} {$path}: not in the contract"];
        }
        $response = $op['responses'][(string) $status] ?? $op['responses'][$status] ?? null;
        if (! $response) {
            return ["{$method} {$path}: status {$status} not in the contract"];
        }
        $response = self::resolve($response);
        $schema = $response['content']['application/json']['schema'] ?? null;
        if ($schema === null) {
            return null;
        }
        $errors = [];
        self::validate($schema, $body, '$', $errors);

        return array_map(fn ($e) => "{$method} {$path} {$status}: {$e}", $errors);
    }

    private static function resolve(array $node): array
    {
        while (isset($node['$ref'])) {
            $parts = explode('/', substr($node['$ref'], 2));
            $node = self::spec();
            foreach ($parts as $p) {
                $node = $node[$p];
            }
        }

        return $node;
    }

    private static function validate(array $schema, mixed $v, string $at, array &$errors): void
    {
        $schema = self::resolve($schema);
        if ($v === null) {
            if (! ($schema['nullable'] ?? false) && ! in_array('null', (array) ($schema['type'] ?? []), true) && isset($schema['type'])) {
                $errors[] = "{$at} is null, not {$schema['type']}";
            }

            return;
        }
        foreach ($schema['allOf'] ?? [] as $part) {
            self::validate($part, $v, $at, $errors);
        }
        foreach (['oneOf', 'anyOf'] as $k) {
            if (isset($schema[$k])) {
                foreach ($schema[$k] as $option) {
                    $try = [];
                    self::validate($option, $v, $at, $try);
                    if (! $try) {
                        return;
                    }
                }
                $errors[] = "{$at} matches none of its {$k}";

                return;
            }
        }
        $type = $schema['type'] ?? (isset($schema['properties']) ? 'object' : null);
        $types = array_values(array_diff((array) $type, ['null']));
        if (! $types) {
            return;
        }
        $ok = false;
        foreach ($types as $t) {
            $ok = $ok || match ($t) {
                'object' => is_array($v) && (! array_is_list($v) || $v === []),
                'array' => is_array($v) && array_is_list($v),
                'string' => is_string($v),
                'integer' => is_int($v),
                'number' => is_int($v) || is_float($v),
                'boolean' => is_bool($v),
                default => true,
            };
        }
        if (! $ok) {
            $errors[] = "{$at} is ".get_debug_type($v).', not '.implode('|', $types);

            return;
        }
        if (isset($schema['enum']) && ! in_array($v, $schema['enum'], true)) {
            $errors[] = "{$at} is ".json_encode($v).', not one of '.json_encode($schema['enum']);
        }
        if (in_array('object', $types, true) && is_array($v)) {
            foreach ($schema['required'] ?? [] as $key) {
                if (! array_key_exists($key, $v)) {
                    $errors[] = "{$at}.{$key} is missing";
                }
            }
            foreach ($schema['properties'] ?? [] as $key => $prop) {
                if (array_key_exists($key, $v)) {
                    self::validate($prop, $v[$key], "{$at}.{$key}", $errors);
                }
            }
            if (is_array($schema['additionalProperties'] ?? null)) {
                foreach ($v as $key => $item) {
                    if (! isset($schema['properties'][$key])) {
                        self::validate($schema['additionalProperties'], $item, "{$at}.{$key}", $errors);
                    }
                }
            }
        }
        if (in_array('array', $types, true) && isset($schema['items']) && is_array($v)) {
            foreach (array_slice($v, 0, 50) as $n => $item) {
                self::validate($schema['items'], $item, "{$at}[{$n}]", $errors);
            }
        }
    }
}
