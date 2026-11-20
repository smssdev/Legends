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

// كل خطأ يمكن أن تعطيه الواجهة، بصيغة Problem Details (الفصل 4)
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
        return new self(401, 'لم تسجّل الدخول', 'أرسل رمزاً صالحاً: Authorization: Bearer <token>.');
    }

    public static function badLogin(): self
    {
        return new self(401, 'البريد أو كلمة المرور خطأ');
    }

    public static function emailTaken(): self
    {
        return new self(409, 'البريد مسجّل من قبل');
    }

    public static function outOfStock(int $id, int $stock): self
    {
        return new self(409, 'المخزون لا يكفي', __('بقي من المنتج :id: :stock.', ['id' => $id, 'stock' => $stock]));
    }

    public static function unknownProduct(int $id): self
    {
        return new self(422, 'منتج مجهول', null, ['product_id' => $id]);
    }

    public static function keyReused(): self
    {
        return new self(422, 'مفتاح Idempotency-Key مستعمل', 'استُعمل هذا المفتاح بجسم مختلف.');
    }

    // كيف تصير استثناءات Laravel نفسه مشكلات
    public static function from(Throwable $e): self
    {
        return match (true) {
            $e instanceof self => $e,
            $e instanceof AuthenticationException => self::unauthenticated(),
            $e instanceof ValidationException => new self(422, 'طلب غير صالح', null, [
                'errors' => collect($e->errors())->map(fn ($messages, $field) => [
                    'field' => $field, 'message' => $messages[0],
                ])->values()->all(),
            ]),
            $e instanceof ThrottleRequestsException => new self(429, 'محاولات كثيرة',
                __('حاول بعد :seconds ثانية.', ['seconds' => $e->getHeaders()['Retry-After']]), [], $e->getHeaders()),
            $e instanceof NotFoundHttpException => new self(404, 'غير موجود'),
            default => new self(500, 'خطأ في الخادم'),
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
