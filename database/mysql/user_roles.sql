CREATE TABLE `user_roles` (
  `uid` int unsigned NOT NULL,
  `rid` int unsigned NOT NULL,
  PRIMARY KEY (`uid`, `rid`),
  KEY (`rid`)
);