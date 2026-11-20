.[] | (.method | . + " " * (10 - length)) + " "
    + (.uri | . + " " * (24 - length)) + " "
    + (.action | ltrimstr("App\\Http\\Controllers\\"))
