<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Specialists [docs/features/specialists.md, Sprint 31]: a club's contracts, each of one type, from when to when. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('staff_specialists', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('type', 14);    // doctor, lawyer, keeper_coach, physio
            $table->unsignedBigInteger('cost');
            $table->timestamp('starts_at');
            $table->timestamp('ends_at');
            $table->string('idempotency_key', 80)->unique();
            $table->timestamps();

            $table->index(['club_id', 'type', 'ends_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('staff_specialists');
    }
};
