CREATE TABLE reviews (
  code integer NOT NULL auto_increment PRIMARY KEY,
  sku varchar(32) NOT NULL,
  uid integer NOT NULL,
  name varchar(255) NOT NULL DEFAULT '',
  created datetime NOT NULL,
  rating integer NOT NULL DEFAULT 0,
  title varchar(255) NOT NULL DEFAULT '',
  public boolean NOT NULL DEFAULT FALSE,
  approved boolean DEFAULT NULL,
  review text NOT NULL DEFAULT '',
  KEY(sku)  
);
