<?php

namespace App\Orders\Domain;

use DomainException;

// errors that speak the business's language; each adapter decides what they become
abstract class OrderError extends DomainException {}
