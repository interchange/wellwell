CREATE TABLE categories
(
  "code" serial NOT NULL,
  "name" varchar(255) NOT NULL DEFAULT '',
  "description" text NOT NULL DEFAULT '',
  "type" varchar(32) NOT NULL DEFAULT '',
  "parent" int4 NOT NULL DEFAULT 0,
  "priority" int4 NOT NULL DEFAULT 0,
  "uri" varchar(255) NOT NULL DEFAULT '',
  "inactive" bool DEFAULT false,
  CONSTRAINT categories_pkey PRIMARY KEY ("code")
);
CREATE INDEX idx_categories_parent ON categories (parent,type);
CREATE INDEX idx_categories_uri ON categories (uri);
