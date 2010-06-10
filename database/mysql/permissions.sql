CREATE TABLE permissions (
  rid int not null default 0,
  uid int not null default 0,
  perm varchar(255) not null default ''
);

INSERT INTO permissions (rid,perm) VALUES (1,'anonymous');
INSERT INTO permissions (rid,perm) VALUES (2,'authenticated');

