<?php

use App\Auth\Username;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The account's own things [X4, 2026-10-24]: a username of English letters only (the old accounts get one from
 * their email), a picture kept in the database (so Litestream saves it with the rest), and a holiday for the whole
 * account. A holiday in one league alone now needs a reason its owner approves.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('username', 20)->nullable()->unique()->after('name');
            $table->timestamp('vacation_from')->nullable();
            $table->timestamp('vacation_until')->nullable();
        });
        foreach (DB::table('users')->whereNull('username')->orderBy('id')->get(['id', 'email', 'name']) as $u) {
            DB::table('users')->where('id', $u->id)->update(['username' => Username::free(strtok((string) $u->email, '@') ?: (string) $u->name)]);
        }
        Schema::create('user_avatars', function (Blueprint $table) {
            $table->foreignId('user_id')->primary()->constrained()->cascadeOnDelete();
            $table->binary('image');            // a 256-pixel square JPEG
            $table->timestamp('updated_at')->nullable();
        });
        Schema::table('league_memberships', function (Blueprint $table) {
            $table->unsignedTinyInteger('vacation_request_days')->nullable();
            $table->string('vacation_reason', 300)->nullable();
            $table->timestamp('vacation_requested_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('league_memberships', fn (Blueprint $table) => $table->dropColumn(['vacation_request_days', 'vacation_reason', 'vacation_requested_at']));
        Schema::dropIfExists('user_avatars');
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['username']);
            $table->dropColumn(['username', 'vacation_from', 'vacation_until']);
        });
    }
};
