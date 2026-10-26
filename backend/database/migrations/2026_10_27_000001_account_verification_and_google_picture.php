<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [UP5, UP6] The owner's spec (1, 2026-10-26): an account may be made with a name, a username and a password alone
 * (no email), Google's picture becomes the coach's, and the 1000 welcome coins wait for the account to be
 * verified with a code the support sends on WhatsApp.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('email')->nullable()->change();
            $table->string('google_picture', 500)->nullable()->after('google_id');
            $table->timestamp('account_verified_at')->nullable()->after('email_verified_at');
        });
        Schema::create('account_codes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('code_hash');
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('expires_at');
            $table->timestamp('used_at')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'used_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('account_codes');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['google_picture', 'account_verified_at']);
        });
    }
};
