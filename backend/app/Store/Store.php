<?php

namespace App\Store;

use App\Models\User;
use App\Notifications\StoreDealNotice;
use App\Support\GameClock;
use App\Support\Mailer;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 43 W2, Hamza 2026-11-05] The store: what the admin adds, bought by WhatsApp. Base packages stay until the
 * admin edits or deletes them; an offer shows until its end (ends_at), then goes by itself. Each has a title, a
 * description, its price and the price before a discount, its currency, and a picture cut to one size. No payment in
 * the game: the button opens WhatsApp with the item and the coach's account number.
 */
class Store
{
    public const KINDS = ['package', 'offer'];

    /** What the coaches see now: the visible packages, and the visible offers not yet ended. */
    public static function shown(): array
    {
        $now = GameClock::now();

        return DB::table('store_items')->where('visible', true)
            ->where(fn ($q) => $q->where('kind', 'package')->orWhere(fn ($o) => $o->where('kind', 'offer')->where('ends_at', '>', $now)))
            ->orderByRaw("case when kind = 'offer' then 0 else 1 end")->orderBy('sort')->orderByDesc('id')->get()
            ->map(fn ($i) => self::card($i))->all();
    }

    /** Everything, for the admin (ended offers too, marked). */
    public static function all(): array
    {
        return DB::table('store_items')->orderByDesc('id')->get()->map(fn ($i) => self::card($i))->all();
    }

    public static function card(object $i): array
    {
        $old = $i->old_price !== null ? (int) $i->old_price : null;
        $ends = $i->ends_at ? Carbon::parse($i->ends_at, 'UTC') : null;

        return ['id' => (int) $i->id, 'kind' => $i->kind, 'title' => $i->title, 'description' => $i->description,
            'price' => (int) $i->price, 'old_price' => $old, 'currency' => $i->currency,
            // The discount from the two prices, whole per cent.
            'discount' => $old !== null && $old > (int) $i->price ? intdiv(($old - (int) $i->price) * 100, $old) : null,
            'visible' => (bool) $i->visible, 'sort' => (int) $i->sort,
            'ends_at' => $ends?->toIso8601ZuluString(), 'ended' => $ends !== null && $ends->lte(GameClock::now()),
            'image_url' => $i->has_image ? url("/api/v1/store/{$i->id}/image").'?v='.Carbon::parse($i->updated_at, 'UTC')->getTimestamp() : null,
            'emailed_at' => $i->emailed_at ? Carbon::parse($i->emailed_at, 'UTC')->toIso8601ZuluString() : null];
    }

    /** The WhatsApp chat for an item: the store's number and a ready message with the coach's account number. */
    public static function whatsapp(array $card, User $user, bool $en = false): string
    {
        $text = $en ? "I want: {$card['title']} (my account number {$user->account_no})"
            : "أريد: {$card['title']} (رقم حسابي {$user->account_no})";

        return 'https://wa.me/'.config('game.store.whatsapp').'?text='.rawurlencode($text);
    }

    /** Add (no $id) or change an item; a new picture replaces the old one. Returns its id. */
    public static function save(array $data, ?string $jpeg, ?int $id = null): int
    {
        $now = GameClock::now();
        $row = ['kind' => $data['kind'], 'title' => trim($data['title']), 'description' => trim($data['description']),
            'price' => (int) $data['price'], 'old_price' => isset($data['old_price']) && $data['old_price'] !== null ? (int) $data['old_price'] : null,
            'currency' => trim((string) ($data['currency'] ?? '')) ?: (string) config('game.store.currency'),
            'visible' => (bool) ($data['visible'] ?? true), 'sort' => (int) ($data['sort'] ?? 0),
            // A package has no end; an offer always has one.
            'ends_at' => $data['kind'] === 'offer' ? Carbon::parse($data['ends_at'])->utc() : null, 'updated_at' => $now];

        return DB::transaction(function () use ($row, $jpeg, $id, $now) {
            if ($id === null) {
                $id = DB::table('store_items')->insertGetId($row + ['created_at' => $now, 'has_image' => $jpeg !== null]);
            } else {
                abort_unless(DB::table('store_items')->where('id', $id)->update($row + ($jpeg !== null ? ['has_image' => true] : [])) === 1, 404, 'العنصر غير موجود.');
            }
            if ($jpeg !== null) {
                DB::table('store_item_images')->where('store_item_id', $id)->delete();
                DB::table('store_item_images')->insert(['store_item_id' => $id, 'image' => $jpeg, 'created_at' => $now]);
            }

            return $id;
        });
    }

    public static function delete(int $id): void
    {
        DB::transaction(function () use ($id) {
            DB::table('store_item_images')->where('store_item_id', $id)->delete();
            abort_unless(DB::table('store_items')->where('id', $id)->delete() === 1, 404, 'العنصر غير موجود.');
        });
    }

    /** A coach's choice: the store's offers by email (notify_prefs.email_offers, off by default). */
    public static function wantsEmail(int $userId): bool
    {
        $prefs = json_decode((string) DB::table('users')->where('id', $userId)->value('notify_prefs'), true) ?: [];

        return ($prefs['email_offers'] ?? false) === true;
    }

    /** An item by email to every coach who asked for offers and confirmed his email. Returns how many. */
    public static function email(int $id): int
    {
        $item = DB::table('store_items')->where('id', $id)->first();
        abort_unless($item, 404, 'العنصر غير موجود.');
        $card = self::card($item);
        abort_if($card['ended'], 409, 'انتهى هذا العرض.');
        $sent = 0;
        if (Mailer::live()) {
            foreach (User::query()->whereNotNull('email')->whereNotNull('email_verified_at')->whereNotNull('notify_prefs')->cursor() as $user) {
                if (! self::wantsEmail($user->id)) {
                    continue;
                }
                $en = ($user->locale ?? 'ar') === 'en';
                $price = fn (?int $p) => $p === null ? null : number_format($p).' '.$card['currency'];
                $user->notify(new StoreDealNotice(
                    subject: $card['title'], title: $card['title'], lead: $card['description'],
                    packs: [['name' => $card['title'], 'gives' => $card['description'], 'price' => $price($card['price']), 'was' => $price($card['old_price']),
                        'badge' => $card['discount'] ? "-{$card['discount']}%" : null]],
                    until: $card['ends_at'] ? Carbon::parse($card['ends_at'])->setTimezone('Africa/Cairo')->format('Y-m-d H:i') : null, path: '/store', en: $en, image: $card['image_url'], whatsapp: self::whatsapp($card, $user, $en)));
                $sent++;
            }
        }
        DB::table('store_items')->where('id', $id)->update(['emailed_at' => GameClock::now()]);

        return $sent;
    }
}
