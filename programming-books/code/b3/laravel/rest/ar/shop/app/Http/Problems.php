<?php

declare(strict_types=1);

namespace App\Http;

use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

// Every problem the API can return, and how other exceptions become one.
final class Problems
{
    public static function from(Throwable $e): Problem
    {
        return match (true) {
            $e instanceof Problem => $e,
            $e instanceof ValidationException => new Problem(422, 'invalid-request',
                __('problems.invalid'), null, ['errors' => self::errors($e)]),
            $e instanceof NotFoundHttpException => self::notFound($e->getPrevious()),
            $e instanceof ThrottleRequestsException => new Problem(
                429, 'too-many-requests', __('problems.limit'), null, [], $e->getHeaders()),
            $e instanceof HttpExceptionInterface => new Problem(
                $e->getStatusCode(), 'http-error', $e->getMessage() ?: __('problems.server')),
            default => new Problem(500, 'server-error', __('problems.server')),
        };
    }

    public static function needIfMatch(): Problem
    {
        return new Problem(428, 'precondition-required', __('problems.precondition'),
            __('problems.need_if_match'));
    }

    public static function stale(): Problem
    {
        return new Problem(412, 'stale', __('problems.stale'),
            __('problems.stale_detail'));
    }

    public static function outOfStock(int $id, int $stock): Problem
    {
        return new Problem(409, 'out-of-stock', __('problems.stock'),
            __('problems.stock_detail', ['id' => $id, 'stock' => $stock]));
    }

    public static function cannotCancel(int $id, string $status): Problem
    {
        return new Problem(409, 'invalid-state', __('problems.state'),
            __('problems.state_detail', ['id' => $id, 'status' => $status]));
    }

    private static function notFound(?Throwable $previous): Problem
    {
        $detail = __('problems.nothing');
        if ($previous instanceof ModelNotFoundException) {
            $key = 'problems.no_'.strtolower(class_basename($previous->getModel()));
            $detail = __($key, ['id' => implode(', ', $previous->getIds())]);
        }

        return new Problem(404, 'not-found', __('problems.not_found'), $detail);
    }

    /** @return list<array{field: string, message: string}> */
    private static function errors(ValidationException $e): array
    {
        $list = [];
        foreach ($e->errors() as $field => $messages) {
            foreach ($messages as $message) {
                $list[] = ['field' => $field, 'message' => $message];
            }
        }

        return $list;
    }
}
