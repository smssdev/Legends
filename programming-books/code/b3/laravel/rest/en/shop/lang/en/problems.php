<?php

// The texts of the API's problems.
// __('problems.stale') reads them in the app's language.
return [
    'invalid' => 'Invalid request',
    'not_found' => 'Not found',
    'no_product' => 'There is no product :id.',
    'no_order' => 'There is no order :id.',
    'nothing' => 'Nothing here.',
    'precondition' => 'Precondition required',
    'need_if_match' => 'Send If-Match with the ETag you last read.',
    'stale' => 'The product has changed',
    'stale_detail' => 'Someone changed it after you read it. Read it again.',
    'key' => 'Idempotency-Key is required: 8 to 100 characters.',
    'reused' => 'Idempotency key reused',
    'reused_detail' => 'This key was used with a different body.',
    'in_progress' => 'Request in progress',
    'in_progress_detail' => 'A request with this key is still running.',
    'stock' => 'Not enough stock',
    'stock_detail' => 'Only :stock left of product :id.',
    'state' => 'Order cannot be cancelled',
    'state_detail' => 'Order :id is already :status.',
    'limit' => 'Too many requests',
    'server' => 'Server error',
];
