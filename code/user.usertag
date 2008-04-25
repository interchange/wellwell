UserTag user Order function uid
UserTag user Routine <<EOR
sub {
	my ($function, $uid) = @_;
	my ($uref);

	$Tag->perl({tables => 'users'});

	# fetch user record
	unless ($uref = $Db{users}->row_hash($uid)) {
		$uref = {username => 'anonymous'};
	}

	if ($function eq 'name') {
		return $uref->{username};
	}
}
EOR