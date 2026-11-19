# With lazy loading turned off, the N+1 is an error in development
$ php artisan shop:report lazy 2>&1 | grep -E 'LazyLoadingViolation|Attempted to' | head -2
   Illuminate\Database\LazyLoadingViolationException 
  Attempted to lazy load [products] on model [App\Models\Order] but lazy loading is disabled.
