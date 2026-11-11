<?php

/*
 * [Sprint 51 B4] Cross-origin requests to the API: the game's own site only (APP_URL, from PUBLIC_URL on the server). The
 * web is served from the same address (no CORS needed), the app and Unity's player call with a token and are not
 * browsers; Laravel's default ('*') let any site call the API with a stolen token.
 */
$own = rtrim((string) env('APP_URL', 'http://localhost'), '/');

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => array_values(array_unique(array_filter([$own, rtrim((string) env('FRONTEND_URL', ''), '/')]))),
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 3600,
    'supports_credentials' => false,
];
