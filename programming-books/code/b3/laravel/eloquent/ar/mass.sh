# الإسناد الجماعي: الخصائص المسموحة وحدها
$ php artisan shop:mass 2>&1 | grep -E '^\{|MassAssignmentException|fillable property' | head -3
{"name":"Test","price":100,"stock":1}
   Illuminate\Database\Eloquent\MassAssignmentException 
  Add fillable property [id] to allow mass assignment on [App\Models\Product].
