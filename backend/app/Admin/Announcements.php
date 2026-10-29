<?php

namespace App\Admin;

use App\Auth\Username;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The developers' announcements as cards [Sprint 21 E7.2, X54 after the owner's picture]: the title and its date, a
 * wide picture, the text, and a button (its label and link: a page of the game, or a site that opens apart). One
 * shape for the coaches' page and the panel.
 */
class Announcements
{
    /** The newest first. */
    public static function list(int $limit = 30): array
    {
        return DB::table('announcements')->leftJoin('users', 'users.id', '=', 'announcements.user_id')->orderByDesc('announcements.id')->limit($limit)
            ->get(['announcements.*', 'users.name', 'users.username'])->map(fn ($a) => self::card($a))->all();
    }

    public static function card(object $a): array
    {
        return ['id' => (int) $a->id, 'title' => $a->title, 'body' => $a->body, 'sent' => (int) $a->sent,
            'image_url' => $a->has_image ? url("/api/v1/announcements/{$a->id}/image") : null,
            'cta' => $a->cta_label && $a->cta_url ? ['label' => $a->cta_label, 'url' => $a->cta_url] : null,
            'sender' => ($a->name ?? null) ? ['name' => $a->name, 'username' => self::shown((string) $a->username), 'official' => Username::official($a->username)] : null,
            'at' => Carbon::parse($a->created_at, 'UTC')->toIso8601ZuluString()];
    }

    /** owner-sizar → Owner-Sizar, as written in the settings. */
    public static function shown(string $username): string
    {
        foreach (config('game.account.official_usernames') as $name) {
            if (strtolower($name) === $username) {
                return $name;
            }
        }

        return $username;
    }
}
