CREATE TABLE path_redirect (
	path_source varchar(255) NOT NULL DEFAULT '',
	path_target varchar(255) NOT NULL DEFAULT '',
	status_code int NOT NULL DEFAULT 0,
	last_used int NOT NULL DEFAULT 0,
	PRIMARY KEY (path_source)
);
