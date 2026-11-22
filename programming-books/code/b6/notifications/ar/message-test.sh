$ flutter test test/message_test.dart
00:00 +0: loading test/message_test.dart
00:00 +0: رسائل الدفع تصير مسارات، أو لا شيء
{type: order_ready, order_id: 42}            -> /orders/42
{type: order_update, order_id: 7}            -> /orders/7
{type: promo}                                -> /
{type: order_ready}                          -> ignored
{type: order_ready, order_id: ../admin}      -> ignored
{type: unknown, order_id: 42}                -> ignored
00:00 +1: All tests passed!
