<?php

namespace App\Http\Errors;

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Session\TokenMismatchException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Throwable;

/**
 * One shape for every API error, in Arabic, for the web and the app alike [Sprint 9 B3]:
 * { "message": "...", "code": "not_found", "errors": { "field": ["..."] } }
 * "errors" only on validation. A message given to abort() in Arabic is kept as it is.
 */
class ApiErrors
{
    public const MESSAGES = [
        400 => ['bad_request', 'الطلب غير صحيح.'],
        401 => ['unauthenticated', 'سجّل الدخول أولاً.'],
        403 => ['forbidden', 'ليست لديك صلاحية لهذا.'],
        404 => ['not_found', 'غير موجود.'],
        405 => ['method_not_allowed', 'هذه الطريقة غير مسموحة هنا.'],
        409 => ['conflict', 'لا يمكن تنفيذ هذا الآن.'],
        410 => ['gone', 'لم يعد متاحاً.'],
        413 => ['too_large', 'الملف أو الطلب أكبر من المسموح.'],
        419 => ['session_expired', 'انتهت الجلسة، حدّث الصفحة وحاول مجدداً.'],
        422 => ['validation', 'تحقق من البيانات المدخلة.'],
        426 => ['update_required', 'حدّث التطبيق إلى آخر إصدار.'],
        429 => ['too_many_requests', 'طلبات كثيرة، حاول بعد قليل.'],
        500 => ['server_error', 'حدث خطأ غير متوقع، حاول مجدداً.'],
        503 => ['unavailable', 'اللعبة في صيانة قصيرة، نعود بعد قليل.'],
    ];

    public static function wants(Request $request): bool
    {
        return $request->is('api/*') || $request->expectsJson();
    }

    public static function render(Throwable $e, Request $request): ?JsonResponse
    {
        if (! self::wants($request)) {
            return null;
        }
        $status = match (true) {
            $e instanceof ValidationException => 422,
            $e instanceof AuthenticationException => 401,
            $e instanceof AuthorizationException => 403,
            $e instanceof ModelNotFoundException => 404,
            $e instanceof TokenMismatchException => 419,
            $e instanceof HttpExceptionInterface => $e->getStatusCode(),
            default => 500,
        };
        [$code, $message] = self::MESSAGES[$status] ?? self::MESSAGES[$status >= 500 ? 500 : 400];
        $own = $e instanceof HttpExceptionInterface || $e instanceof AuthorizationException ? $e->getMessage() : '';
        if ($own !== '' && preg_match('/\p{Arabic}/u', $own)) {
            $message = $own;
        }
        $body = ['message' => $message, 'code' => $code];
        if ($e instanceof ValidationException) {
            $body['errors'] = $e->errors();
        }
        if ($status === 500 && config('app.debug')) {
            $body['debug'] = ['exception' => $e::class, 'message' => $e->getMessage(), 'at' => $e->getFile().':'.$e->getLine()];
        }
        $headers = $e instanceof HttpExceptionInterface ? $e->getHeaders() : [];

        return response()->json($body, $status, $headers);
    }
}
