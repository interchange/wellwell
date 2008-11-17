CREATE TABLE menus
(
  "code" serial NOT NULL,
  "name" varchar(255) NOT NULL DEFAULT '',
  "parent" int4 NOT NULL DEFAULT 0,
  "url" varchar(255) NOT NULL DEFAULT '',
  "permission" varchar(64) NOT NULL DEFAULT '',
  "menu_name" varchar(64) NOT NULL DEFAULT '',
  "weight" int4 NOT NULL DEFAULT 0,
  CONSTRAINT menu_pkey PRIMARY KEY (code)
);
CREATE INDEX idx_menus_menu_name ON menus (menu_name);
