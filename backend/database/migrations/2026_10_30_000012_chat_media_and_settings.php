<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 29 X65] Pictures and voice notes in the chat groups, kept in the database (with its backups, as the avatars)
 * in base64 so both databases read them alike; and the game's settings the admin changes from the panel (the chat's
 * retention, whether media may be sent).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_media', function (Blueprint $t) {
            $t->id();
            $t->foreignId('chat_group_message_id')->unique()->constrained()->cascadeOnDelete();
            $t->string('mime', 40);
            $t->unsignedInteger('bytes');
            $t->unsignedSmallInteger('seconds')->nullable();
            $t->longText('data');
            $t->timestamp('created_at')->nullable();
        });
        Schema::create('game_settings', function (Blueprint $t) {
            $t->string('key', 64)->primary();
            $t->text('value');
            $t->timestamp('updated_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_media');
        Schema::dropIfExists('game_settings');
    }
};
