# The table after the three migrations
$ php artisan db:table products --no-ansi

  public.products ............................................................  
  Columns .................................................................. 7  
  Size .............................................................. 24.00 KB  

  Column ................................................................ Type  
  id int8, autoincrement ......... nextval('products_id_seq'::regclass) bigint  
  name varchar ........................................ character varying(255)  
  price int4 ......................................................... integer  
  stock int4 ....................................................... 0 integer  
  created_at timestamptz, nullable ............... timestamp(0) with time zone  
  updated_at timestamptz, nullable ............... timestamp(0) with time zone  
  sku varchar ......................................... character varying(255)  

  Index ......................................................................  
  products_pkey id ............................................ btree, primary  
  products_sku_unique sku ...................................... btree, unique  
