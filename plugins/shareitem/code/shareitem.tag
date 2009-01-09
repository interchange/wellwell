UserTag shareitem Order function
UserTag shareitem Routine <<EOR
sub {
	my ($function) = @_;

	if ($function eq 'init') {
		$Values->{email} = $Scratch->{email};
		$Values->{name} = "$Values->{first_name} $Values->{last_name}";
		$Values->{recipient} = $Values->{remarks} = '';
		return 1;
	}
	elsif ($function eq 'send') {
		my ($name, $subject);

		# get product name
		$Tag->perl({tables => 'products'});
		$name = $Db{products}->field($Values->{sku}, 'name');
		$subject = errmsg('Recommendation for %s', $name);

		$Tag->email({from => $Values->{email},
			to => $Values->{recipient},
			subject => $subject,
			body => $Values->{remarks}});

		$Tag->warnings('Your recommendation has been submitted.');
		$CGI->{mv_nextpage} = $Values->{sku};
		return 1;
	}
}
EOR

