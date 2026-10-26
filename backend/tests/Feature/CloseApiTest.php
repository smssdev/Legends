<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/** Supabase's public API never reaches the game's tables [X43]: the public key is not a secret. */
class CloseApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_every_table_is_closed_to_the_public_api_and_open_to_the_server(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            $this->artisan('db:close-api')->assertSuccessful();
            $this->markTestSkipped('PostgreSQL only (Supabase).');
        }
        DB::statement("do \$\$ begin if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if; end \$\$");
        DB::statement('grant select on all tables in schema public to anon');
        $this->artisan('db:close-api')->assertSuccessful();
        $this->assertSame(0, DB::table('pg_tables')->where('schemaname', 'public')->where('rowsecurity', false)->count());
        $this->assertFalse((bool) DB::selectOne("select has_table_privilege('anon', 'users', 'select') as ok")->ok);
        // The server, the tables' owner, reads and writes as before.
        $this->assertSame(0, DB::table('users')->count());
    }
}
