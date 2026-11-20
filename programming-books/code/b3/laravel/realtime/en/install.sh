# Broadcasting with Reverb, in one command
$ php artisan install:broadcasting --reverb
   INFO  Published 'broadcasting' configuration file.  
   INFO  Published 'channels' route file.  
   INFO  Discovering packages.  
   INFO  No publishable resources for tag [laravel-assets].  
   INFO  Reverb installed successfully.  
$ grep -E '^(BROADCAST_CONNECTION|REVERB_)' .env
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=…
REVERB_APP_KEY=…
REVERB_APP_SECRET=…
REVERB_HOST="localhost"
REVERB_PORT=8080
REVERB_SCHEME=http
