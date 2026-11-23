<?php

namespace App\Support;

/**
 * [Sprint 75 W8, WEB-08] Whether an address is a page of the web app, for the web server's router
 * (deploy/docker/router.php), which sends the app's page for any address and so answered 200 for one that is not there.
 * The app's routes are web/public/app-routes.json (router.test.ts keeps it the same as web/src/router.ts), written as
 * vue-router writes them: "/leagues/:id(\d+)/newspaper", "/join/:code?". Plain PHP with no framework call, so the router
 * can require this file on its own, as SecurityPolicy.
 */
final class AppPages
{
    /** @param  list<string>  $paths  The app's routes. */
    public static function known(string $uri, array $paths): bool
    {
        foreach ($paths as $path) {
            if (preg_match(self::pattern($path), $uri) === 1) {
                return true;
            }
        }

        return false;
    }

    /**
     * A route as a regular expression: a ":name" segment is any one segment, ":name(re)" one that matches re, and
     * ":name?" may be left out; a slash at the end is allowed and the case ignored, as vue-router matches.
     */
    public static function pattern(string $path): string
    {
        $out = '';
        foreach (explode('/', trim($path, '/')) as $segment) {
            if ($segment === '') {
                continue;
            }
            if (preg_match('/^:\w+(?:\((.+)\))?(\?)?$/', $segment, $m) === 1) {
                $re = ($m[1] ?? '') !== '' ? str_replace('#', '\#', $m[1]) : '[^/]+';
                $out .= ($m[2] ?? '') === '?' ? "(?:/(?:{$re}))?" : "/(?:{$re})";
            } else {
                $out .= '/'.preg_quote($segment, '#');
            }
        }

        return '#^'.$out.'/?$#i';
    }
}
