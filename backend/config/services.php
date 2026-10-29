<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // Google sign-in [PLAN 2.17]: the web client (Socialite) and every client id whose id_token
    // the API accepts (web and Android). Free, from a Google Cloud project.
    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect' => env('GOOGLE_REDIRECT_URI', '/auth/google/callback'),
        'audiences' => array_values(array_filter(array_map('trim', explode(',', (string) env('GOOGLE_CLIENT_ID').','.env('GOOGLE_ANDROID_CLIENT_IDS', ''))))),
        'certs_url' => 'https://www.googleapis.com/oauth2/v3/certs',
    ],

    // [Sprint 22 B4] The Assistant Coach's mind: Gemini on its free tier (Google AI Studio), no subscription. The key is
    // written on the server only (legends-set GEMINI_API_KEY); without it the assistant answers from the game's guide.
    // The models are tried in order: when the first has used up its free day, the next one answers.
    'gemini' => [
        'key' => env('GEMINI_API_KEY'),
        'models' => array_values(array_filter(array_map('trim', explode(',', (string) env('GEMINI_MODELS', 'gemini-2.5-flash,gemini-2.5-flash-lite'))))),
        'url' => 'https://generativelanguage.googleapis.com/v1beta/models',
        'timeout' => 20,
    ],

];
