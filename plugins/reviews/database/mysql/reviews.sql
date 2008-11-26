CREATE TABLE reviews (
  code integer NOT NULL auto_increment PRIMARY KEY,
  sku varchar(32) NOT NULL,
  uid integer NOT NULL,
  created datetime NOT NULL,
  rating integer NOT NULL DEFAULT 0,
  title varchar(255) NOT NULL DEFAULT '',
  review text NOT NULL DEFAULT '',
  KEY(sku)  
);