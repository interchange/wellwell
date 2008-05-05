CREATE TABLE page_components (
  "page" varchar(255) NOT NULL,
  "component" varchar(255) NOT NULL,
  "container" varchar(255) NOT NULL,
  "selector" varchar(255) NOT NULL,
  "weight" int4 NOT NULL,
  CONSTRAINT page_components_pkey PRIMARY KEY (page, component, container, selector, weight)
);
