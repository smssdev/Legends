<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [X54] An announcement as a card (the owner's picture, 2026-10-29): its wide image (kept apart, a JPEG of a few
// dozen kilobytes) and a button with its label and link.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('announcements', function (Blueprint $table) {
            $table->string('cta_label', 40)->nullable();
            $table->string('cta_url', 300)->nullable();
            $table->boolean('has_image')->default(false);
        });
        Schema::create('announcement_images', function (Blueprint $table) {
            $table->foreignId('announcement_id')->primary()->constrained()->cascadeOnDelete();
            $table->binary('image');
            $table->timestamp('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('announcement_images');
        Schema::table('announcements', fn (Blueprint $table) => $table->dropColumn(['cta_label', 'cta_url', 'has_image']));
    }
};
