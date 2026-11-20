<?php

// PHP 8 compares a number and a non-numeric string as strings: 0 == "a" is false.
$pairs = [[0, "a"], ["1", "01"], ["10", "1e1"], [100, "100"], [null, false], [[], false]];
foreach ($pairs as [$a, $b]) {
    printf("%-6s %-6s  ==  %-5s  ===  %s\n",
        json_encode($a), json_encode($b), json_encode($a == $b), json_encode($a === $b));
}
