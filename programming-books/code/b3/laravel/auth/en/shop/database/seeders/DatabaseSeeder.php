<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // two customers with orders, and an admin (passwords for development only)
        $people = [
            ['sara@example.com', 'Sara', 'customer', [45000, 6000]],
            ['omar@example.com', 'Omar', 'customer', [12000]],
            ['admin@example.com', 'Admin', 'admin', []],
        ];
        foreach ($people as [$email, $name, $role, $totals]) {
            $user = User::forceCreate([
                'email' => $email,
                'name' => $name,
                'role' => $role,
                'password' => strtok($email, '@').'-password-2026',
            ]);
            foreach ($totals as $total) {
                $user->orders()->create(['total' => $total]);
            }
        }
    }
}
