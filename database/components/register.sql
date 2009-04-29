insert into form_series (name, part, label, profile) values ('register', 'register', 'Create New Account', 'register');
insert into form_elements (name, label, component, widget)
	values ('username', 'Username', 'register', ''),
	('email', 'Email', 'register', ''),
	('password', 'Password', 'register', 'password'),
	('password_verify', 'Confirm Password', 'register', 'password');