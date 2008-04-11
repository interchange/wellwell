-- DROP TABLE pages;

CREATE TABLE pages
(
  name varchar(255) NOT NULL,
  "template" varchar(255) NOT NULL,
  CONSTRAINT name PRIMARY KEY (name)
) 
WITHOUT OIDS;
COMMENT ON TABLE pages IS 'Table stores page names and corresponding templates that are applied to that page.';
