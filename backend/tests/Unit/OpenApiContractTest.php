<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use Tests\Support\OpenApiContract;

/** [Sprint 66 T9] The contract's checker finds what a client would trip on (ContractTest relies on it). */
class OpenApiContractTest extends TestCase
{
    private function row(array $over = []): array
    {
        return [...['id' => 1, 'platform' => 'web', 'version' => 'v', 'path' => '/', 'message' => 'm', 'stack' => '', 'count' => 2,
            'first_seen_at' => '2026-11-15T10:00:00Z', 'last_seen_at' => '2026-11-15T10:00:00Z'], ...$over];
    }

    public function test_a_matching_answer_passes(): void
    {
        $this->assertSame([], OpenApiContract::check('get', '/admin/client-errors', 200, ['errors' => [$this->row()], 'extra' => true]));
    }

    public function test_it_finds_a_missing_field_a_wrong_type_a_wrong_enum_and_a_null(): void
    {
        $found = OpenApiContract::check('get', '/admin/client-errors', 200, ['errors' => [
            $this->row(['count' => '2']),
            array_diff_key($this->row(), ['message' => 1]),
            $this->row(['platform' => 'desktop']),
            $this->row(['path' => null]),
        ]]);
        $this->assertCount(4, $found);
        $this->assertStringContainsString('$.errors[0].count is string, not integer', $found[0]);
        $this->assertStringContainsString('$.errors[1].message is missing', $found[1]);
        $this->assertStringContainsString('$.errors[2].platform is "desktop"', $found[2]);
        $this->assertStringContainsString('$.errors[3].path is null', $found[3]);
        $this->assertSame(['get /admin/client-errors 200: $.errors is missing'], OpenApiContract::check('get', '/admin/client-errors', 200, []));
    }

    public function test_an_undocumented_status_or_route_is_said(): void
    {
        $this->assertSame(['get /admin/client-errors: status 418 not in the contract'], OpenApiContract::check('get', '/admin/client-errors', 418, []));
        $this->assertSame(['get /nowhere: not in the contract'], OpenApiContract::check('get', '/nowhere', 200, []));
    }
}
