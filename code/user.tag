UserTag user Order function uid
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

=head2

=back

=head1 AUTHORS

Stefan Hornburg <racke@linuxia.de>

Jure Kodzoman <jure@tenalt.com>

=cut

EOD

UserTag user Routine <<EOR
sub {
	my ($function, $uid) = @_;
	my ($uref);

	unless ($uid){
		$uid = $Session->{username};
	}

	$Tag->perl({tables => 'users'});

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
