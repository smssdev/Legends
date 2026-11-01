<?php

namespace App\Admin;

use App\Rules\NotJunk;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * [X61, Sprint 30 P3] What a test left where the players see it (App\Rules\NotJunk): the announcements (and their
 * copies in the inboxes) and the rewarded ads, which the admin removes from the panel (or content:junk on the
 * server), and the test-named leagues, listed only (a league with players is ended by hand).
 */
class JunkContent
{
    /** @return array{announcements: Collection, house_ads: Collection, leagues: Collection} */
    public static function find(): array
    {
        return [
            'announcements' => DB::table('announcements')->orderBy('id')->get(['id', 'title', 'body'])->filter(fn ($a) => NotJunk::junk((string) $a->title) || NotJunk::junk((string) $a->body))->values(),
            'house_ads' => DB::table('house_ads')->orderBy('id')->get(['id', 'title', 'body'])->filter(fn ($a) => NotJunk::junk((string) $a->title) || NotJunk::junk((string) $a->body))->values(),
            'leagues' => DB::table('leagues')->orderBy('id')->get(['id', 'name'])->filter(fn ($l) => NotJunk::junk((string) $l->name))->values(),
        ];
    }

    /** Removes the test announcements (with their inbox copies and pictures) and the test rewarded ads. */
    public static function purge(): array
    {
        $found = self::find();
        $ids = $found['announcements']->pluck('id')->all();
        $ads = $found['house_ads']->pluck('id')->all();
        DB::transaction(function () use ($ids, $ads) {
            if ($ids) {
                // The inbox copies: by the announcement's id, or (older ones without it) by a test title or text.
                DB::table('messages')->where('type', 'announcement')->orderBy('id')->chunkById(500, function ($rows) use ($ids) {
                    $gone = $rows->filter(function ($m) use ($ids) {
                        $p = json_decode((string) $m->payload, true) ?: [];

                        return in_array($p['announcement_id'] ?? null, $ids, true) || NotJunk::junk((string) ($p['title'] ?? '')) || NotJunk::junk((string) ($p['body'] ?? ''));
                    })->pluck('id');
                    DB::table('messages')->whereIn('id', $gone)->delete();
                });
                DB::table('announcement_images')->whereIn('announcement_id', $ids)->delete();
                DB::table('announcements')->whereIn('id', $ids)->delete();
            }
            if ($ads) {
                DB::table('house_ads')->whereIn('id', $ads)->delete();
            }
        });

        return ['announcements' => count($ids), 'house_ads' => count($ads)];
    }
}
