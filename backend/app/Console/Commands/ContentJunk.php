<?php

namespace App\Console\Commands;

use App\Admin\JunkContent;
use Illuminate\Console\Command;

/**
 * [X61] What a test left where players see it (App\Admin\JunkContent): the announcements, [Sprint 30 P3] the rewarded
 * ads, and the leagues whose name is a test's. It only lists, unless the owner adds --delete-announcements on the
 * server (the announcements and the rewarded ads; the panel has the same button): the server's data is the owner's,
 * so nothing is removed by a migration or a deploy, and leagues never here (ended from the admin panel, by hand).
 */
class ContentJunk extends Command
{
    protected $signature = 'content:junk {--delete-announcements : Remove the test announcements (with their inbox copies) and the test rewarded ads}';

    protected $description = 'List (or remove) the test announcements, rewarded ads and test-named leagues players can see';

    public function handle(): int
    {
        $found = JunkContent::find();
        $this->table(['announcement', 'title'], $found['announcements']->map(fn ($a) => [$a->id, $a->title])->all());
        $this->table(['house ad', 'title'], $found['house_ads']->map(fn ($a) => [$a->id, $a->title])->all());
        $this->table(['league', 'name'], $found['leagues']->map(fn ($l) => [$l->id, $l->name])->all());
        if (! $this->option('delete-announcements')) {
            return self::SUCCESS;
        }
        $gone = JunkContent::purge();
        $this->info("Removed {$gone['announcements']} test announcement(s) and {$gone['house_ads']} test rewarded ad(s).");

        return self::SUCCESS;
    }
}
