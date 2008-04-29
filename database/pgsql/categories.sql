CREATE TABLE categories
(
  name varchar(255) NOT NULL,
  category_id serial NOT NULL,
  parent int8,
  CONSTRAINT categories_pkey PRIMARY KEY (category_id)
) 
WITHOUT OIDS;
