<?php

// One tap on a payment, in a process of its own (LeagueClaimRaceTest): boots the app on the test database,
// waits for the shared start moment, spends with the given key, and prints the balance after or "refused".

use App\League\ClubLedger;
use Illuminate\Contracts\Console\Kernel;
use Symfony\Component\HttpKernel\Exception\HttpException;

require __DIR__.'/../../vendor/autoload.php';
$app = require __DIR__.'/../../bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();

[, $clubId, $key, $amount, $startAt] = $argv;
while (microtime(true) < (float) $startAt) {
    usleep(500);
}

try {
    echo ClubLedger::post((int) $clubId, 'wages', (int) $amount, $key, spend: true);
} catch (HttpException $e) {
    echo $e->getStatusCode() === 409 ? 'refused' : 'error: '.$e->getMessage();
} catch (Throwable $e) {
    echo 'error: '.get_class($e).': '.$e->getMessage();
}
