<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The stadium [PLAN 2.9, Sprint 29]: each club's three sections with the stage reached and the parts done in the
 * next one, and the one part being built (one at a time), with its price and when it is done.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stadium_sections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('section', 10);             // seats, pitch, training
            $table->unsignedTinyInteger('stage')->default(0);   // stages finished, 0..3
            $table->unsignedTinyInteger('parts')->default(0);   // parts finished of the next stage, 0..4
            $table->timestamps();

            $table->unique(['club_id', 'section']);
        });
        Schema::create('stadium_builds', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('section', 10);
            $table->unsignedTinyInteger('stage');      // the stage this part belongs to, 1..3
            $table->unsignedTinyInteger('part');       // 1..5
            $table->unsignedBigInteger('cost');
            $table->timestamp('ends_at');
            $table->string('status', 9)->default('building');   // building, done
            $table->string('idempotency_key', 80)->unique();
            $table->timestamps();

            $table->index(['status', 'ends_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stadium_builds');
        Schema::dropIfExists('stadium_sections');
    }
};
