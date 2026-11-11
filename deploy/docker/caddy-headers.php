<?php

// [Sprint 52 B3] Caddy sends the built files itself, before PHP: their security headers are written here, at the
// container's start, from App\Http\Security\SecurityPolicy (the one source, Sprint 51), into a snippet the Caddyfile
// imports. The pages (HTML) still go through router.php, which adds their scripts' hashes.
require (getenv('BACKEND_DIR') ?: __DIR__.'/backend').'/app/Http/Security/SecurityPolicy.php';

echo "(security_headers) {\n\theader {\n\t\t-X-Powered-By\n\t\t-Server\n";
// Behind the server's nginx every request is HTTPS (and a browser ignores HSTS over plain HTTP).
foreach (App\Http\Security\SecurityPolicy::headers(true) as $name => $value) {
    echo "\t\t".$name.' "'.str_replace('"', '\"', $value)."\"\n";
}
echo "\t}\n}\n";
