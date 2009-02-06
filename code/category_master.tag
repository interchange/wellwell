UserTag category_master Order name parent type
UserTag category_master AddAttr
UserTag category_master Routine <<EOR
sub {
	my ($name, $parent, $type, $opt) = @_;
	my ($cat_q, $set, $code, $uri);

	$parent ||= 0;
	$type ||= '';

	$Tag->perl({tables => 'categories'});

	$cat_q = $Db{categories}->quote($name);
	$set = $Db{categories}->query(qq{select code from categories where name = $cat_q and parent = $parent});

	if (@$set) {
		return $set->[0]->[0];
	}

	# create category
	$code = $Db{categories}->set_slice('', [qw/name parent type/], [$name, $parent, $type]);

	# determine URI for category
	$uri = $Tag->category_path({code => $code, showname => 1, 
		filter => 'category_uri', joiner => '/', prefix => $opt->{prefix}});
	$Db{categories}->set_field($code, 'uri', $uri);

	return $code;
}
EOR
