<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [X45] The sessions can live in the server's own SQLite file beside the cache (SESSION_CONNECTION=cache_db, Render):
// no trip to Supabase on every request. The same table as Laravel's, in that file.
return new class extends Migration
{
    public function getConnection(): ?string
    {
        return 'cache_db';
    }

    public function up(): void
    {
        if (Schema::connection('cache_db')->hasTable('sessions')) {
            return;
        }
        Schema::connection('cache_db')->create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::connection('cache_db')->dropIfExists('sessions');
    }
};
