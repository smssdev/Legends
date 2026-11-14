<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 69] A league's Telegram group may carry the league's own chat both ways, when its owner turns it on (off by
 * default: what members write in the game reaches Telegram only with the owner's choice).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messenger_groups', function (Blueprint $t) {
            $t->boolean('bridge')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('messenger_groups', fn (Blueprint $t) => $t->dropColumn('bridge'));
    }
};
