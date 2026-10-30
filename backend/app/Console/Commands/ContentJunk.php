<?php

namespace App\Console\Commands;

use App\Rules\NotJunk;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * [X61] What a test left where players see it: the announcements (and their copies in the inboxes) and the leagues
 * whose name is a test's (App\Rules\NotJunk). It only lists, unless the owner adds --delete-announcements on the
 * server: the server's data is the owner's, so nothing is removed by a migration or a deploy, and leagues never here
 * (a league with players is ended from the admin panel, by hand).
 */
class ContentJunk extends Command
{
    protected $signature = 'content:junk {--delete-announcements : Remove the test announcements and their inbox copies}';

    protected $description = 'List (or remove) the test announcements and test-named leagues players can see';

    public function handle(): int
    {
        $ads = DB::table('announcements')->get(['id', 'title', 'body'])->filter(fn ($a) => NotJunk::junk($a->title) || NotJunk::junk($a->body));
        $leagues = DB::table('leagues')->get(['id', 'name'])->filter(fn ($l) => NotJunk::junk((string) $l->name));
        $this->table(['announcement', 'title'], $ads->map(fn ($a) => [$a->id, $a->title])->all());
        $this->table(['league', 'name'], $leagues->map(fn ($l) => [$l->id, $l->name])->all());
        if (! $this->option('delete-announcements') || $ads->isEmpty()) {
            return self::SUCCESS;
        }
        $ids = $ads->pluck('id')->all();
        DB::transaction(function () use ($ids) {
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
        });
        $this->info("Removed {$ads->count()} test announcement(s).");

        return self::SUCCESS;
    }
}
