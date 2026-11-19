<?php

foreach ([['abc', 0], ['1', '1.0'], [null, 0], ['', null], ['0', false], [' 1', 1]] as [$a, $b]) {
    printf("%-6s == %-5s  %s
", json_encode($a), json_encode($b), json_encode($a == $b));
}
