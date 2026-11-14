<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 67] The game's bots on Telegram and WhatsApp (App\Messenger):
 *  - messenger_links: an account linked to its chat on one of them (the Telegram chat's number, or the WhatsApp phone
 *    number the coach wrote from), when he last wrote (WhatsApp writes to him free only within 24 hours of it), and
 *    whether he silenced the notifications;
 *  - messenger_codes: the one-time code the profile gives to link, for a few minutes;
 *  - messenger_groups: a league's Telegram group, linked by the league's owner, where each round's results are posted;
 *  - messenger_posts: what the bot posted to the game's public channel, the last ones kept for the admins to copy.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('messenger_links', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->string('platform', 10);
            $t->string('chat_id', 64);
            $t->boolean('muted')->default(false);
            $t->timestamp('last_inbound_at')->nullable();
            $t->timestamp('linked_at');
            $t->unique(['platform', 'chat_id']);
            $t->unique(['user_id', 'platform']);
        });
        Schema::create('messenger_codes', function (Blueprint $t) {
            $t->string('code', 10)->primary();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->timestamp('expires_at')->index();
        });
        Schema::create('messenger_groups', function (Blueprint $t) {
            $t->id();
            $t->foreignId('league_id')->unique()->constrained()->cascadeOnDelete();
            $t->string('chat_id', 64)->unique();
            $t->foreignId('linked_by')->nullable()->constrained('users')->nullOnDelete();
            $t->unsignedBigInteger('season_posted')->nullable();
            $t->unsignedSmallInteger('round_posted')->default(0);
            $t->timestamp('linked_at');
        });
        Schema::create('messenger_posts', function (Blueprint $t) {
            $t->id();
            $t->string('kind', 20);
            $t->text('text');
            $t->timestamp('created_at')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messenger_posts');
        Schema::dropIfExists('messenger_groups');
        Schema::dropIfExists('messenger_codes');
        Schema::dropIfExists('messenger_links');
    }
};
