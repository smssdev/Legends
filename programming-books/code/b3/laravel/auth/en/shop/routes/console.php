<?php

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Hash;

Artisan::command('shop:hash', function () {
    $password = 'correct horse battery staple';
    $a = Hash::make($password);
    $b = Hash::make($password);
    $this->line("hash 1 $a");
    $this->line("hash 2 $b");
    $this->line('right password: '.json_encode(Hash::check($password, $a)));
    $this->line('wrong password: '.json_encode(Hash::check($password.'r', $a)));
    $start = hrtime(true);
    Hash::make($password);
    $this->line('one hash took '.round((hrtime(true) - $start) / 1e6).' ms');
});

Artisan::command('shop:rehash', function () {
    // exercise 3: a hash made with fewer rounds than the configuration asks for
    $old = Hash::make('correct horse battery staple', ['rounds' => 10]);
    $this->line('needs rehash (10 rounds): '.json_encode(Hash::needsRehash($old)));
    $new = Hash::make('correct horse battery staple');
    $this->line('needs rehash (12 rounds): '.json_encode(Hash::needsRehash($new)));
});

Artisan::command('shop:jwt', function () {
    $secret = 'a secret only the server knows';
    $url = fn (string $bytes) => rtrim(strtr(base64_encode($bytes), '+/', '-_'), '=');
    $b64 = fn (array $value) => $url(json_encode($value));
    $sign = fn (string $data) => $url(hash_hmac('sha256', $data, $secret, true));

    // a JWT: header and payload in base64url, then their HMAC
    $header = $b64(['alg' => 'HS256', 'typ' => 'JWT']);
    $payload = $b64(['sub' => 2, 'role' => 'customer', 'exp' => 1795000000]);
    $token = "$header.$payload.".$sign("$header.$payload");
    $this->line("token: $token");

    // anyone can read the payload: it is encoded, not encrypted
    $read = fn (string $part) => base64_decode(strtr($part, '-_', '+/'));
    $this->line('payload, read without the key: '.$read(explode('.', $token)[1]));

    $valid = function (string $jwt) use ($sign) {
        [$h, $p, $signature] = explode('.', $jwt);

        return hash_equals($sign("$h.$p"), $signature);
    };
    $this->line('signature valid: '.json_encode($valid($token)));
    // change the payload, keep the signature
    $forged = $b64(['sub' => 2, 'role' => 'admin', 'exp' => 1795000000]);
    $signature = explode('.', $token)[2];
    $this->line('tampered token valid: '.json_encode($valid("$header.$forged.$signature")));
});
