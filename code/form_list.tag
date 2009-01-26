UserTag form_list Order name
UserTag form_list Routine <<EOR
sub {
	my ($name) = @_;
	my ($name_qtd, $sql, $set, @records, @list, @field_names, %field_hash);

	# get form series from the database
	$Tag->perl({tables => 'form_series'});

	@field_names = $Db{form_series}->columns();
	for (my $i = 0; $i < @field_names; $i++) {
		$field_hash{$field_names[$i]} = $i;
	}

	$name_qtd = $Db{form_series}->quote($name);
	$sql = qq{select * from form_series where name = $name_qtd order by position};
	$set = $Db{form_series}->query({sql => $sql, hashref => 1});

	# walk through series, call apply for flags
	for (my ($i,$pos) = (0,1); $i < @$set; $i++) {
		my $fs = $set->[$i];

		if ($fs->{apply}) {
			my (@apply, $tag, $ret, @tokens, %flags);

			@apply = split(/,/, $fs->{apply});
			$tag = shift(@apply);
			$ret = $Tag->$tag(@apply);

			@tokens = split(/,/, $ret);
			for my $tok (@tokens) {
				$flags{$tok} = 1;
			}
			if ($flags{inactive}) {
				next;
			}
		} 
		$fs->{position} = $pos++;

		if (wantarray()) {
			# convert hash to array
			my $record = [];

			for my $fname (@field_names) {
				push(@$record, $fs->{$fname});
			}

			push (@records, $record);
		}
		else {
			push (@list, $fs);
		}
	}

	if (wantarray()) {
		@list = (\@records, \%field_hash, @field_names);
		return @list;
	} 
	else {
		return \@list;
	}
}
EOR
