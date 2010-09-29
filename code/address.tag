UserTag address Order function type name
UserTag address AddAttr
UserTag address HasEndTag
UserTag address Routine <<EOR
sub {
	my ($function, $type, $name, $opt, $body) = @_;
	my ($hash, $prefix, @fields, $fieldstr, %address, $set, $aref, $uid, $aid, $ret);

	$Tag->perl({tables => 'addresses country'});

	if ($opt->{hash}) {
		$hash = $opt->{hash};
	}
	else {
		$Tag->update('values');
		$hash = $Values;
	}

	$prefix = $opt->{prefix} || '';

	@fields = qw(company first_name last_name street_address zip city phone fax country);
	$fieldstr = join(',', 'aid', @fields);

	$uid = $opt->{uid} || $Session->{username};

	if ($uid =~ /^\d+$/) {
		# check for an existing address
		$set = $Db{addresses}->query(qq{select $fieldstr from addresses where uid = %s and type = '%s' and archived is FALSE}, $uid, $type);
		if (@$set) {
			$aref = $set->[0];
			$aid = shift(@$aref);
			
			for my $f (@fields) {
				$address{$f} = shift(@$aref);
			}
		}
	}
	
	if ($function eq 'display') {
		# turn country code into a name
		if ($address{country}) {
			$address{country} = $Db{country}->field($address{country}, 'name');
		}

		# strip all strings to avoid display of pure whitespace strings
		for (keys %address) {
			$address{$_} =~ s/^\s+//;
			$address{$_} =~ s/\s+$//;
		}

		return $Tag->uc_attr_list({hash => \%address, body => $body});
	}
	elsif ($function eq 'set') {
		# create/update address
		for (@fields) {
			if (exists $hash->{"${prefix}$_"}) {
				$address{$_} = $hash->{"${prefix}$_"};
			} else {
				$address{$_} = '';
			}
		}
		$address{uid} = $uid;
		$address{type} = $type;
		$address{last_modified} = $Tag->time({format => '%s'});

		$ret = $Db{addresses}->set_slice($aid, %address);
		return $ret;
	}
	elsif ($function eq 'compare') {
		# compare stored address with values submitted by user
		my (@diffs);

		for (@fields) {
			if ($address{$_} ne $hash->{"${prefix}$_"}) {
				push (@diffs, $_);
			}
		}		

		wantarray ? @diffs : scalar(@diffs);
	}
	elsif ($function eq 'get') {
		$address{uid} = $uid;
		$address{type} = $type;
		if ($name) {
			if ($name eq 'aid') {
				return $aid;
			}
			return $address{$name};
		}
		return \%address;
	}
	elsif ($function eq 'archive') {
		$address{uid} = $uid;
		$address{type} = $type;
		$address{archived} = 1;
		$ret = $Db{addresses}->set_slice('', %address);
		return $ret;
	} 
	elsif ($function eq 'update') {
		if ($Tag->address({function => 'compare', 
						type => $type, 
						prefix => $prefix})) {
			my ($set_transactions, $set_returns);	
		
			# address has changed, check if used in orders/returns
			$Tag->perl({tables => 'transactions returns'});

			$set_transactions = $Db{transactions}->query(qq{select count(*) from transactions where aid_$type = $aid}); 
			$set_returns = $Db{returns}->query(qq{select count(*) from returns where rma_aid = $aid}); 

			if ($set_transactions->[0]->[0] || $set_returns->[0]->[0]) {
				# archive address
				$Db{addresses}->set_field($aid, archived => 1);
			}

			# new address
			$Tag->address({function => 'set', 
				type => $type, 
				prefix => $prefix});
		}

		return $aid;
	}
	elsif ($function eq 'load') {
		for (@fields) {
			if (exists $address{$_}) {
				$hash->{"${prefix}$_"} = $address{$_};
			} else {
				$hash->{"${prefix}$_"} = '';
			}
		}
		return $aid;
	}
}
EOR
