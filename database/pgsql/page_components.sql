-- DROP TABLE page_components;

CREATE TABLE page_components
(
  "page" varchar(255) NOT NULL,
  "component" varchar(255) NOT NULL,
  "container" varchar(255) NOT NULL,
  "selector" varchar(255) NOT NULL,
  "weight" INT NOT NULL,
  CONSTRAINT page_components_pkey PRIMARY KEY (page, component, container, selector, weight)
) 
WITHOUT OIDS;
COMMENT ON TABLE page_components IS 'This table contains information on which components are used by which page, and in which of the containers on the page they are located in.';
