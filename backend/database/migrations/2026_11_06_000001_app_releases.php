<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 15 D1, the owner's request 2026-11-06] The app's versions to download from the site: the admin uploads the
 * Android APK in pieces, and the site hands out the latest ready one. The file lives on the server's downloads volume.
 * Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_releases', function (Blueprint $table) {
            $table->id();
            $table->string('platform', 8);          // android
            $table->string('version', 20);
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('bytes');    // the size announced, then checked
            $table->unsignedBigInteger('received')->default(0);
            $table->string('sha256', 64)->nullable();
            $table->string('status', 10)->default('uploading');   // uploading | ready
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedInteger('downloads')->default(0);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->index(['platform', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_releases');
    }
};
