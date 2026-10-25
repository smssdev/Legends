<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Morale [X25]: each club's, its run of results without a win, and the tickets to cheer at another club's match. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('clubs', function (Blueprint $t) {
            $t->unsignedTinyInteger('morale')->default(70);
            $t->unsignedTinyInteger('winless_run')->default(0);
        });
        Schema::create('match_tickets', function (Blueprint $t) {
            $t->id();
            $t->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            // The club whose coach bought it, and the side he cheers.
            $t->foreignId('club_id')->constrained()->cascadeOnDelete();
            $t->string('side', 4);
            $t->unsignedInteger('price');
            $t->timestamp('created_at');
            $t->unique(['fixture_id', 'club_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_tickets');
        Schema::table('clubs', function (Blueprint $t) {
            $t->dropColumn(['morale', 'winless_run']);
        });
    }
};
