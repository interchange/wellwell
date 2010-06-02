CREATE TABLE `roles` (
  `rid` int unsigned auto_increment NOT NULL,
  `name` varchar(32) NOT NULL,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY (`rid`)
);

INSERT INTO roles (rid,name,label) VALUES (1, 'anonymous', 'Anonymous Users');
INSERT INTO roles (rid,name,label) VALUES (2, 'authenticated', 'Authenticated Users');
