UserTag user Order function uid
UserTag user AddAttr
UserTag user Documentation <<EOD

=head1 NAME

user - Access to user information

=head1 SYNOPSIS

[user function uid]

=head1 DESCRIPTION

Access to user related information

=over 4

=item function

Data you wish to retrieve. Can be name or email.

=item uid

User ID. Default to current logged in user.

=back

=head1 EXAMPLES

=item Retrieve current users email

[user email]

=item Retrieve username of user 23223

[user name 23223]

=item Determine whether user racke exists

[user function=exists username=racke]

=head2

=back

=head1 AUTHORS

Stefan Hornburg <racke@linuxia.de>

Jure Kodzoman <jure@tenalt.com>

=cut

EOD

UserTag user Routine <<EOR
sub {
	my ($function, $uid, $opt) = @_;
	my ($uref);

	$Tag->perl({tables => 'users'});

	if ($function eq 'exists') {
		my ($field, $val, $set);

		# lookup username
		if ($opt->{username}) {
			$field = 'username';
			$val = $opt->{username};
		}
		elsif ($opt->{email}) {
			$field = 'email';
			$val = $opt->{email};
		}
		elsif ($uid) {
			$field = 'uid';
			$val = $uid;
		}
		else {
			return;
		}

		$set = $Db{users}->query(qq{select uid from users where $field = '%s'}, $val);

		if (@$set) {
			return $set->[0]->[0];
		}

		return;
	}

	unless ($uid){
		$uid = $Session->{username};
	}

	# fetch user record
	unless ($uref = $Db{users}->row_hash($uid)) {
		$uref = {username => 'anonymous'};
	}

	if ($function eq 'name') {
		return $uref->{username};
	}
	elsif ($function eq 'email') {
		return $uref->{email};
	}
}
EOR
