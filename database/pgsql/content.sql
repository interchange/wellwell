CREATE TABLE "content" (
  "code" serial NOT NULL,
  "type" varchar(32) NOT NULL,
  "uid" int8 NOT NULL,
  "title" varchar(255) NOT NULL,
  "body" text NOT NULL,
  "locale" varchar(255) NOT NULL DEFAULT 'en_US'::character varying,
  "created" timestampz NOT NULL,
  PRIMARY KEY ("code")
);
