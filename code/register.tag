UserTag register Routine <<EOR
sub {
	my ($uid, $pass, $ret);

	$Tag->perl({tables => 'users'});
	$Tag->update('values');

	# generate uid in advance if necessary
    $uid = $Db{users}->autosequence();

	# username,email
	unless ($Values->{username}) {
		$Values->{username} = $Values->{email};
	}

	# remember password
	$pass = $CGI->{password};

	# create account without using [userdb] - too cumbersome
	$uid = $Db{users}->set_slice([{dml => 'insert'}, $uid], 
		username => $Values->{username},
		email => $Values->{email},
		password => $pass);

	if ($uid) {
		# login with new account for verification
		$ret = $Tag->userdb({function => 'login',
			username => $Values->{email},
			password => $pass,
			verify => $pass});
	}

	unless ($ret) {
		$Tag->error({name => 'register',
			set => q{Account creation failed. Please contact our support team.}});
	}

	return 1;
}
EOR
