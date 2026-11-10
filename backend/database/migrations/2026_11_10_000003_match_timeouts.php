<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** [Sprint 50 M14] A side's one timeout in a live league match: when it was called and until when play waits. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_timeouts', function (Blueprint $t) {
            $t->id();
            $t->foreignId('match_id')->constrained()->cascadeOnDelete();
            $t->string('side', 4);
            $t->unsignedTinyInteger('tick');
            $t->unsignedBigInteger('until_ms');
            $t->timestamp('created_at')->nullable();
            $t->unique(['match_id', 'side']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_timeouts');
    }
};
