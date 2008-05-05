CREATE TABLE "users" (
  "uid" serial,
  "username" varchar(32),
  "email" varchar(255) NOT NULL,
  "password" varchar(255) NOT NULL,
  CONSTRAINT users_pkey PRIMARY KEY ("uid")
);
