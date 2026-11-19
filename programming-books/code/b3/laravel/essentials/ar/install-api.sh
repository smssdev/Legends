# أضف ملف مسارات الواجهة (وSanctum، ونستخدمه في الفصل 9)
$ php artisan install:api --no-interaction --no-ansi 2>&1 | grep -E 'INFO|tokens_table'
   INFO  Discovering packages.  
   INFO  No publishable resources for tag [laravel-assets].  
   INFO  Published API routes file.  
   INFO  Running migrations.  
  2026_11_19_201618_create_personal_access_tokens_table ......... 10.70ms DONE
   INFO  API scaffolding installed. Please add the [Laravel\Sanctum\HasApiTokens] trait to your User model.  
