<?php

use App\Support\Baskets;

it('keeps a basket touched 29 minutes ago', function () {
    $touched = now();
    // move the application's clock instead of waiting 30 minutes
    $this->travel(29)->minutes();
    expect(Baskets::isExpired($touched))->toBeFalse();
});

it('releases a basket left for 30 minutes', function () {
    $touched = now();
    $this->travel(30)->minutes();
    expect(Baskets::isExpired($touched))->toBeTrue();
});
