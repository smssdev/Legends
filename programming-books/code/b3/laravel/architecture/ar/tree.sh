# وحدة الطلبات
$ find app/Orders -name '*.php' | sort
app/Orders/Actions/PlaceOrder.php
app/Orders/Domain/OrderError.php
app/Orders/Domain/OrderRules.php
app/Orders/Domain/OutOfStock.php
app/Orders/Domain/PlacedOrder.php
app/Orders/Domain/TooMany.php
app/Orders/Domain/UnknownProduct.php
app/Orders/Http/PlaceOrderController.php
app/Orders/Infrastructure/LogMailer.php
app/Orders/Infrastructure/QueryBuilderOrderStore.php
app/Orders/Ports/Mailer.php
app/Orders/Ports/OrderStore.php
