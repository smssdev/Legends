<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 66 B1] The errors the web and the app meet on the players' devices, one row per distinct error with how often
 * it came: the platform, the version, the screen's path, the message and the first lines of its trace. No account, no
 * address, nothing personal (App\Support\ClientErrors scrubs the text). Kept 30 days after it was last seen.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('client_errors', function (Blueprint $t) {
            $t->id();
            $t->string('fingerprint', 40)->unique();
            $t->string('platform', 10);
            $t->string('version', 20);
            $t->string('path', 200);
            $t->string('message', 300);
            $t->text('stack');
            $t->unsignedInteger('count')->default(1);
            $t->timestamp('first_seen_at');
            $t->timestamp('last_seen_at')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('client_errors');
    }
};
