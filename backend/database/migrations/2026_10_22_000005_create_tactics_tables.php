<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tactics and the pre-match lock [PLAN 2.13, 2.14]. A club's tactics use the engine's own keys (App\Engine\
 * MatchSetup::DEFAULT_TACTICS; no row = those neutral defaults, as a bot plays). Five minutes before a match
 * each side's sheet (lineup after the automatic fix, takers and tactics) is frozen in fixture_sheets.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tactics', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('plan', 8);
            $table->unsignedTinyInteger('tackling');
            $table->unsignedTinyInteger('pressing');
            $table->unsignedTinyInteger('style');
            $table->unsignedTinyInteger('tempo');
            $table->string('att', 8);
            $table->string('mid', 8);
            $table->string('def', 10);
            $table->boolean('trap');
            $table->string('marking', 4);
            $table->timestamps();
        });

        Schema::create('fixture_sheets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('formation', 16);
            $table->json('slots');
            $table->json('starters');
            $table->json('bench');
            $table->json('takers');
            // Everything; only the four the opponent may see leave the server for him [PLAN 2.13].
            $table->json('tactics');
            // Who came in for whom at the lock: [{out, in, slot}].
            $table->json('fixes');
            $table->timestamp('locked_at');

            $table->unique(['fixture_id', 'club_id']);
        });

        Schema::table('fixtures', function (Blueprint $table) {
            $table->timestamp('referee_at')->nullable()->after('referee_strictness');
            $table->timestamp('locked_at')->nullable()->after('referee_at');
        });
    }

    public function down(): void
    {
        Schema::table('fixtures', function (Blueprint $table) {
            $table->dropColumn(['referee_at', 'locked_at']);
        });
        Schema::dropIfExists('fixture_sheets');
        Schema::dropIfExists('tactics');
    }
};
