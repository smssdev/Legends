<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 29] Tournaments, national teams and chat groups.
 *  - A tournament is a league of kind "tournament" (every screen and the live match work in it): its format (a league,
 *    groups then a knockout, or a knockout), the groups' count and how many go on from each, one leg or two, and the
 *    template it came from (World Cup, Club World Cup, AFCON, EURO, Asian Cup, or custom).
 *  - A national team is a master club of source "nation", its squad made from the players of its nationality.
 *  - The clubs of a tournament in groups carry their group; a knockout tie after the groups names where its two
 *    sides come from ("A1" is group A's winner).
 *  - Chat groups: any coaches, by invitation, with their messages.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', function (Blueprint $t) {
            $t->string('kind', 12)->default('league');
            $t->string('format', 12)->nullable();
            $t->unsignedTinyInteger('group_count')->nullable();
            $t->unsignedTinyInteger('advance_per_group')->nullable();
            $t->unsignedTinyInteger('legs')->nullable();
            $t->string('tournament_template', 16)->nullable();
        });
        Schema::table('master_clubs', function (Blueprint $t) {
            $t->string('nation', 64)->nullable();
            $t->string('confederation', 8)->nullable();
        });
        Schema::table('clubs', function (Blueprint $t) {
            $t->unsignedTinyInteger('group_no')->nullable();
        });
        Schema::table('cup_ties', function (Blueprint $t) {
            $t->string('home_from', 4)->nullable();
            $t->string('away_from', 4)->nullable();
        });

        Schema::create('chat_groups', function (Blueprint $t) {
            $t->id();
            $t->string('name', 60);
            $t->foreignId('owner_id')->nullable()->constrained('users')->nullOnDelete();
            // The group a league or tournament makes for its members, kept in step with them.
            $t->foreignId('league_id')->nullable()->unique()->constrained()->cascadeOnDelete();
            $t->string('invite_code', 10)->unique();
            $t->timestamps();
        });
        Schema::create('chat_group_members', function (Blueprint $t) {
            $t->id();
            $t->foreignId('chat_group_id')->constrained()->cascadeOnDelete();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->boolean('is_admin')->default(false);
            $t->unsignedBigInteger('last_read_id')->default(0);
            $t->boolean('muted')->default(false);
            $t->timestamps();
            $t->unique(['chat_group_id', 'user_id']);
            $t->index('user_id');
        });
        Schema::create('chat_group_messages', function (Blueprint $t) {
            $t->id();
            $t->foreignId('chat_group_id')->constrained()->cascadeOnDelete();
            // Empty for the group's own notes ("X joined"), and for a deleted account's messages.
            $t->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $t->string('kind', 8)->default('text');
            $t->text('body');
            $t->unsignedBigInteger('reply_to_id')->nullable();
            $t->timestamp('created_at')->nullable();
            $t->timestamp('deleted_at')->nullable();
            $t->index(['chat_group_id', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_group_messages');
        Schema::dropIfExists('chat_group_members');
        Schema::dropIfExists('chat_groups');
        Schema::table('cup_ties', fn (Blueprint $t) => $t->dropColumn(['home_from', 'away_from']));
        Schema::table('clubs', fn (Blueprint $t) => $t->dropColumn('group_no'));
        Schema::table('master_clubs', fn (Blueprint $t) => $t->dropColumn(['nation', 'confederation']));
        Schema::table('leagues', fn (Blueprint $t) => $t->dropColumn(['kind', 'format', 'group_count', 'advance_per_group', 'legs', 'tournament_template']));
    }
};
