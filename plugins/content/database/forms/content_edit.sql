insert into form_series (name, part, label, profile, position) 
	values ('content_edit', 'content_edit', 'Edit Content', 'content_edit', 1);
insert into form_components (name, part, component, location)
	values ('content_edit', 'content_edit', 'fckeditor_js', 'prepend');
insert into form_elements (name, label, component, widget)
	values ('title', 'Title', 'content_edit', ''),
	('body', 'Body', 'content_edit', 'htmlarea'),
	('uri', 'Path', 'content_edit', ''),
	('code', '', 'content_edit', 'hidden');
