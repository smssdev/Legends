<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Rules\NotJunk;
use App\Store\Store;
use App\Support\Avatar;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** [Sprint 43 W2] The store for the coaches, and its items for the admin (add, change, hide, delete, email). */
class StoreController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $en = ($request->user()->locale ?? 'ar') === 'en';

        return response()->json(['items' => array_map(fn ($c) => $c + ['whatsapp_url' => Store::whatsapp($c, $request->user(), $en)], Store::shown()),
            'whatsapp' => '+'.config('game.store.whatsapp')]);
    }

    public function image(int $id): Response
    {
        $image = DB::table('store_item_images')->where('store_item_id', $id)->value('image');
        abort_unless($image !== null, 404);
        $image = is_resource($image) ? stream_get_contents($image) : $image;

        return response($image, 200, ['Content-Type' => 'image/jpeg', 'Cache-Control' => 'public, max-age=604800, immutable']);
    }

    public function adminIndex(): JsonResponse
    {
        return response()->json(['items' => Store::all(), 'currency' => config('game.store.currency'),
            'image' => ['width' => (int) config('game.store.image_w'), 'height' => (int) config('game.store.image_h')]]);
    }

    public function store(Request $request): JsonResponse
    {
        abort_if(DB::table('store_items')->count() >= (int) config('game.store.max_items'), 409, 'بلغ المتجر أقصى عدد من العناصر. احذف ما لا تحتاجه.');
        $id = Store::save($data = $this->validated($request, true), $this->picture($request));

        return response()->json(['item' => Store::card(DB::table('store_items')->where('id', $id)->first())], 201);
    }

    /** A change (a POST: a picture comes as a form). */
    public function update(Request $request, int $id): JsonResponse
    {
        Store::save($this->validated($request, false), $this->picture($request), $id);

        return response()->json(['item' => Store::card(DB::table('store_items')->where('id', $id)->first())]);
    }

    public function destroy(int $id): JsonResponse
    {
        Store::delete($id);

        return response()->json(['ok' => true]);
    }

    public function email(int $id): JsonResponse
    {
        return response()->json(['sent' => Store::email($id)]);
    }

    private function validated(Request $request, bool $new): array
    {
        $c = config('game.store');
        $data = $request->validate([
            'kind' => ['required', Rule::in(Store::KINDS)],
            'title' => ['required', 'string', 'max:80', new NotJunk],
            'description' => ['required', 'string', 'max:600', new NotJunk],
            'price' => ['required', 'integer', 'min:0', 'max:100000000'],
            'old_price' => ['nullable', 'integer', 'gt:price', 'max:100000000'],
            'currency' => ['nullable', 'string', 'max:12'],
            'visible' => ['sometimes', 'boolean'],
            'sort' => ['sometimes', 'integer', 'between:0,1000'],
            // An offer lasts until a time the admin sets: in the future, and not too far.
            'ends_at' => ['nullable', 'required_if:kind,offer', 'date', 'after:'.GameClock::now()->toIso8601String(),
                'before:'.GameClock::now()->addDays((int) $c['offer_max_days'])->toIso8601String()],
            'image' => [$new ? 'required' : 'nullable', 'image', 'mimes:jpeg,png,webp,gif', 'max:'.$c['image_max_kb']],
        ], ['ends_at.required_if' => 'حدّد متى ينتهي العرض.', 'old_price.gt' => 'السعر قبل الخصم أكبر من السعر.', 'image.required' => 'ارفع صورة من جهازك.']);

        return $data;
    }

    private function picture(Request $request): ?string
    {
        if (! $request->hasFile('image')) {
            return null;
        }
        $jpeg = Avatar::cover((string) file_get_contents($request->file('image')->getRealPath()), (int) config('game.store.image_w'), (int) config('game.store.image_h'));
        abort_unless($jpeg !== null, 422, 'تعذرت قراءة الصورة، جرّب صورة أخرى.');

        return $jpeg;
    }
}
