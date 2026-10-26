<?php

namespace App\Http\Errors;

use App\Http\Middleware\SetLocale;
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
 * One shape for every API error, in Arabic (or English [UP2]), for the web and the app alike [Sprint 9 B3]:
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

    /** [UP2] The same in English, for a coach who plays in English. */
    public const MESSAGES_EN = [
        400 => 'The request is not valid.',
        401 => 'Sign in first.',
        403 => 'You are not allowed to do this.',
        404 => 'Not found.',
        405 => 'This method is not allowed here.',
        409 => 'This cannot be done right now.',
        410 => 'No longer available.',
        413 => 'The file or request is too large.',
        419 => 'The session expired. Refresh the page and try again.',
        422 => 'Check the data you entered.',
        426 => 'Update the app to the latest version.',
        429 => 'Too many requests. Try again shortly.',
        500 => 'Something went wrong. Try again.',
        503 => 'The game is under short maintenance. Back soon.',
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
        // From the request itself: an error thrown before the locale's middleware ran (signing in) still knows it.
        $english = SetLocale::of($request) === 'en';
        if ($english) {
            $message = self::MESSAGES_EN[$status] ?? self::MESSAGES_EN[$status >= 500 ? 500 : 400];
        }
        if ($own !== '' && preg_match('/\p{Arabic}/u', $own)) {
            // [UP2] The game's own words in English from lang/en.json, when they have been put there.
            $message = $english && ($en = __($own, [], 'en')) !== $own ? $en : $own;
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
