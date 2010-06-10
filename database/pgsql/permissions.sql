CREATE TABLE permissions (
  rid integer not null default 0,
  uid integer not null default 0,
  perm varchar(255) not null default ''
);

INSERT INTO permissions (rid,perm) VALUES (1,'anonymous');
INSERT INTO permissions (rid,perm) VALUES (2,'authenticated');
