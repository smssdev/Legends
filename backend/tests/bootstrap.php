<?php

// Tests run on real SQLite files (CLAUDE.md). RefreshDatabase only wipes the
// default connection, so start every run from fresh data, cache and queue files.
foreach (glob(__DIR__.'/../database/testing*.sqlite*') as $file) {
    unlink($file);
}

require __DIR__.'/../vendor/autoload.php';
