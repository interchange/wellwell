CREATE TABLE "image_sizes"
(
  "name" varchar(64) NOT NULL,
  "width" int4,
  "height" int4,
  CONSTRAINT image_sizes_pkey PRIMARY KEY ("name")
);
