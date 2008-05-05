CREATE TABLE categories
(
  "code" serial NOT NULL,
  "name" varchar(255) NOT NULL,
  "parent" int4,
  CONSTRAINT categories_pkey PRIMARY KEY ("code")
);
