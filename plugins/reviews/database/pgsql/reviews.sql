CREATE TABLE reviews (
  code serial PRIMARY KEY,
  sku varchar(32) NOT NULL,
  uid integer NOT NULL,
  name varchar(255) NOT NULL DEFAULT '',
  created timestamp NOT NULL,
  rating integer NOT NULL DEFAULT 0,
  title varchar(255) NOT NULL DEFAULT '',
  public boolean NOT NULL DEFAULT FALSE,
  review text NOT NULL DEFAULT ''
);
CREATE INDEX reviews_sku ON reviews(sku);
