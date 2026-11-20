<?php

namespace App\Http;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

// every error the API can give, in the Problem Details format (Chapter 4)
final class Problem extends HttpException
{
    public function __construct(
        int $status,
        public readonly string $title,
        public readonly ?string $detail = null,
        public readonly array $extra = [],
        array $headers = [],
    ) {
        parent::__construct($status, $title, null, $headers);
    }

    public static function unauthenticated(): self
    {
        return new self(401, 'Not signed in', 'Send a valid token: Authorization: Bearer <token>.');
    }

    public static function badLogin(): self
    {
        return new self(401, 'Email or password is wrong');
    }

    public static function emailTaken(): self
    {
        return new self(409, 'Email already registered');
    }

    public static function outOfStock(int $id, int $stock): self
    {
        return new self(409, 'Not enough stock', __('Product :id has :stock left.', ['id' => $id, 'stock' => $stock]));
    }

    public static function unknownProduct(int $id): self
    {
        return new self(422, 'Unknown product', null, ['product_id' => $id]);
    }

    public static function keyReused(): self
    {
        return new self(422, 'Idempotency-Key reused', 'This key was used with a different body.');
    }

    // how Laravel's own exceptions become problems
    public static function from(Throwable $e): self
    {
        return match (true) {
            $e instanceof self => $e,
            $e instanceof AuthenticationException => self::unauthenticated(),
            $e instanceof ValidationException => new self(422, 'Invalid request', null, [
                'errors' => collect($e->errors())->map(fn ($messages, $field) => [
                    'field' => $field, 'message' => $messages[0],
                ])->values()->all(),
            ]),
            $e instanceof ThrottleRequestsException => new self(429, 'Too many attempts',
                __('Try again in :seconds seconds.', ['seconds' => $e->getHeaders()['Retry-After']]), [], $e->getHeaders()),
            $e instanceof NotFoundHttpException => new self(404, 'Not found'),
            default => new self(500, 'Server error'),
        };
    }

    public function render(Request $request): JsonResponse
    {
        $body = array_filter([
            'title' => $this->title,
            'status' => $this->getStatusCode(),
            'detail' => $this->detail,
            'instance' => $request->getRequestUri(),
            ...$this->extra,
        ], fn ($value) => $value !== null);
        $headers = ['Content-Type' => 'application/problem+json', ...$this->getHeaders()];

        return response()->json($body, $this->getStatusCode(), $headers, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
}
