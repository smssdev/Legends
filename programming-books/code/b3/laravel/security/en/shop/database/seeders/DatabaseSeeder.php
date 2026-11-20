<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::forceCreate([
            'name' => 'Sara', 'email' => 'sara@example.com',
            'role' => 'admin', 'password' => 'sara-password-2026',
        ]);
        User::forceCreate([
            'name' => 'Omar', 'email' => 'omar@example.com',
            'role' => 'customer', 'password' => 'omar-password-2026',
        ]);
        DB::table('products')->insert([
            ['name' => 'Robot kit', 'price' => 45000],
            ['name' => 'Spare wheels', 'price' => 6000],
        ]);
    }
}
