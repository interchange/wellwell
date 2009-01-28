CREATE TABLE "roles" (
  "rid" serial,
  "name" varchar(32) NOT NULL,
  "label" varchar(255) NOT NULL,
  CONSTRAINT roles_pkey PRIMARY KEY ("rid")
);