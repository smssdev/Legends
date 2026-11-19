<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Http\Problem;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

// Safe retries: the same Idempotency-Key gets the same answer; the work is done once.
final class Idempotent
{
    public function handle(Request $request, Closure $next): Response
    {
        $key = (string) $request->header('Idempotency-Key');
        if (strlen($key) < 8 || strlen($key) > 100) {
            throw new Problem(400, 'invalid-request', __('problems.invalid'),
                __('problems.key'));
        }
        // Until Chapter 9 gives us real users, a header names the client.
        $client = (string) $request->header('X-Client-Id', 'anonymous');
        $id = 'idempotency:'.$client.':'.$key;
        $fingerprint = hash('sha256', $request->getContent());

        $lock = Cache::lock($id.':lock', 30); // طلب واحد لكل مفتاح في كل لحظة
        if (! $lock->get()) {
            throw new Problem(409, 'in-progress', __('problems.in_progress'),
                __('problems.in_progress_detail'));
        }
        try {
            $saved = Cache::get($id);
            if ($saved !== null) {
                if ($saved['fingerprint'] !== $fingerprint) {
                    throw new Problem(422, 'idempotency-key-reused',
                        __('problems.reused'), __('problems.reused_detail'));
                }
                $headers = array_filter($saved['headers']);
                $headers['Idempotent-Replayed'] = 'true';

                return response($saved['body'], $saved['status'], $headers);
            }
            $response = $next($request);
            if ($response->isSuccessful()) {
                // يُحفظ يوماً، والطلب الفاشل لا يُحفظ، فيجوز تكراره
                Cache::put($id, [
                    'fingerprint' => $fingerprint,
                    'status' => $response->getStatusCode(),
                    'body' => $response->getContent(),
                    'headers' => [
                        'Content-Type' => $response->headers->get('Content-Type'),
                        'Location' => $response->headers->get('Location'),
                    ],
                ], now()->addDay());
            }

            return $response;
        } finally {
            $lock->release();
        }
    }
}
