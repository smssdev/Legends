<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 20 S4] The game's own rewarded ads (the owner's decision 2026-10-29: our own free provider): the ads the
// developers write, and each watch the server timed, so a reward is paid only for an ad watched to its end.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('house_ads', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();   // the developer who wrote it
            $table->string('title', 80);
            $table->string('body', 300);
            $table->string('cta_label', 40)->nullable();
            $table->string('cta_url', 300)->nullable();
            $table->unsignedSmallInteger('seconds')->default(30);
            $table->boolean('active')->default(true);
            $table->unsignedInteger('views')->default(0);
            $table->timestamps();
        });
        Schema::create('ad_watches', function (Blueprint $table) {
            $table->id();
            $table->string('token', 64)->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('house_ad_id')->nullable();   // null: one of the built-in ads
            $table->unsignedSmallInteger('seconds');
            $table->timestamp('started_at');
            $table->timestamp('used_at')->nullable();
            $table->index(['user_id', 'started_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ad_watches');
        Schema::dropIfExists('house_ads');
    }
};
