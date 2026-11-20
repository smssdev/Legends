# الأسماء التي تبدأ بـ «bit h»، بين 500,000
$ psql shop -At -c "SELECT name FROM businesses WHERE lower(name) LIKE 'bit h%' ORDER BY lower(name) LIMIT 5" | head -2
Bit Hair 100032
Bit Hair 100096
$ psql shop -At -c "EXPLAIN (ANALYZE, COSTS OFF) SELECT name FROM businesses WHERE lower(name) LIKE 'bit h%' ORDER BY lower(name) LIMIT 5" | grep -E '^ *(->|Limit|Exec)'
Limit
  ->  Sort
        ->  Bitmap Heap Scan on businesses
              ->  Bitmap Index Scan on businesses_name_prefix
Execution Time: 15.527 ms
$ psql shop -At -c "SELECT name FROM businesses WHERE search_key LIKE 'bit h%' ORDER BY search_key LIMIT 5" | head -2
Bit Hair 100032
Bit Hair 100096
$ psql shop -At -c "EXPLAIN (ANALYZE, COSTS OFF) SELECT name FROM businesses WHERE search_key LIKE 'bit h%' ORDER BY search_key LIMIT 5" | grep -E '^ *(->|Limit|Exec)'
Limit
  ->  Index Scan using businesses_search_key on businesses
Execution Time: 0.086 ms
