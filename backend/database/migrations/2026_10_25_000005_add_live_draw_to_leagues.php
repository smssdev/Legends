<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** The live draw [X26]: its time, the seed (secret until the draw) and its announced hash, and the drawn order. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', function (Blueprint $t) {
            $t->timestamp('draw_at')->nullable();
            $t->unsignedBigInteger('draw_seed')->nullable();
            $t->string('draw_commit', 64)->nullable();
            $t->timestamp('drawn_at')->nullable();
            $t->json('draw_order')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('leagues', fn (Blueprint $t) => $t->dropColumn(['draw_at', 'draw_seed', 'draw_commit', 'drawn_at', 'draw_order']));
    }
};
