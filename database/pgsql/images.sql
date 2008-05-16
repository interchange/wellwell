CREATE TABLE "images"
(
  "code" serial NOT NULL,
  "name" varchar(255),
  "format" char(3),
  "created" timestamp,
  "author" int4,
  "inactive" bool DEFAULT false,
  CONSTRAINT images_pkey PRIMARY KEY ("code")
);
