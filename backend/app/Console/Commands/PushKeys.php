<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Minishlink\WebPush\VAPID;

/** The server's VAPID keys for Web Push [Sprint 36]: made once, then kept in .env. */
class PushKeys extends Command
{
    protected $signature = 'push:keys';

    protected $description = 'Make the VAPID keys for Web Push (put them in .env)';

    public function handle(): int
    {
        $keys = VAPID::createVapidKeys();
        $this->line('WEBPUSH_VAPID_PUBLIC='.$keys['publicKey']);
        $this->line('WEBPUSH_VAPID_PRIVATE='.$keys['privateKey']);
        $this->line('ضعهما في .env مرة واحدة، ولا تغيّرهما بعدها (تغييرهما يلغي اشتراكات المتصفحات).');

        return self::SUCCESS;
    }
}
