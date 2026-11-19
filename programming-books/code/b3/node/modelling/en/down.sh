# Undo the last migration, then run it again
$ npm run migrate --silent -- down
Success Down 2026_11_03_001_product_sku_contract
$ npm run migrate --silent
Success Up   2026_11_03_001_product_sku_contract
