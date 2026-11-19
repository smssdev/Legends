<?php

declare(strict_types=1);

namespace App\Http;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;

// An error in the Problem Details format (RFC 9457).
// Throw it from anywhere; bootstrap/app.php renders it.
final class Problem extends HttpException
{
    public function __construct(
        int $status,
        public readonly string $slug,
        public readonly string $title,
        public readonly ?string $detail = null,
        public readonly array $extra = [],
        array $headers = [],
    ) {
        parent::__construct($status, $detail ?? $title, null, $headers);
    }

    public function render(Request $request): JsonResponse
    {
        $body = [
            'type' => "https://bit-shop.example/problems/{$this->slug}",
            'title' => $this->title,
            'status' => $this->getStatusCode(),
            'detail' => $this->detail,
            'instance' => $request->getRequestUri(),
            ...$this->extra,
        ];
        $body = array_filter($body, fn ($value) => $value !== null);
        $headers = ['Content-Type' => 'application/problem+json', ...$this->getHeaders()];
        $flags = JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES;

        return response()->json($body, $this->getStatusCode(), $headers, $flags);
    }
}
