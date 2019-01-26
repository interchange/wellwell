# example setting for central european timezone
# Variable DATETIME_TIMEZONE Europe/Berlin
# Require module DateTime::TimeZone::Europe::Berlin

Require module DateTime
Require module DateTime::Event::Recurrence

CodeDef datetime Filter
CodeDef datetime Routine <<EOF
sub {
	my ($val) = @_;
	my ($newval, %dthash, $tz);

	# try to normalize input
	if ($val !~ /^\d{8,14}$/) {
		$newval = $Tag->filter('date_change', $val);

		if ($newval =~ /^\d{8,14}$/) {
			$val = $newval;
		} else {
			return;
		}
	}

	%dthash = (year => substr($val, 0, 4),
			   month => substr($val, 4, 2),
			   day => substr($val, 6, 2),
			   hour => substr($val, 8, 2) || 0,
			   minute => substr($val, 10, 2) || 0,
			   second => substr($val, 12, 2) || 0,
			  );

	if ($tz = $Tag->var('DATETIME_TIMEZONE', 1)) {
		$dthash{time_zone} = $tz;
	}

	return \%dthash;
}
EOF

UserTag datetime Order function scope from to fmt
UserTag datetime AddAttr
UserTag datetime Routine <<EOR
sub {
	my ($function, $scope, $from, $to, $fmt, $opt) = @_;
	my ($from_dt, $to_dt, $from_now, $tz, %now_hash);

    # locale
    my $locale = $opt->{locale} || $Scratch->{mv_locale};

    if ($locale) {
        $now_hash{locale} = $locale;
    }

	if ($tz = $Tag->var('DATETIME_TIMEZONE', 1)) {
		$now_hash{time_zone} = $tz;
	}

	if (ref($from)) {
		# DateTime object passed directly ?
		if ($from->isa('DateTime')) {
			$from_dt = $from;
		} elsif ($from->isa('DateTime::Duration') && $function eq 'dump') {
			$from_dt = $from;
		}
        if ($locale) {
            $from_dt->set_locale($locale);
        }
	} elsif ($from =~ /\S/) {
		eval {
			$from_dt = DateTime->new(%{$Tag->filter('datetime', $from, $locale)});
		};

		if ($@) {
			unless ($function eq 'check') {
				$Tag->error({name => 'from',
							set => errmsg('invalid date %s', $from)});
			}
			return;
		}
	} else {
		$from_dt = DateTime->now(%now_hash);
		$from_now = 1;
	}

	if ($function eq 'check') {
		# date is valid, return DateTime object
		return $from_dt;
	} elsif ($function eq 'dump') {
		my (%dtdmp, $dtlocdmp);
		# dumping with uneval gives empty string
		my %dtdmp = %$from_dt;
		if (ref($dtdmp{locale})) {
			$dtdmp{locale} = {%{$dtdmp{locale}}};
		}
		return uneval(\%dtdmp);
	}

	unless ($function eq 'sub' || $function eq 'add') {
		if (ref($to) && $to->isa('DateTime')) {	
			$to_dt = $to;
		} elsif ($to =~ /\S/) {
			eval {
				$to_dt = DateTime->new( %{$Tag->filter( 'datetime', $to, $locale )} );
			};	
			if ($@) {
				$Tag->error({name => 'to',
							set => errmsg('invalid date %s', $to)});
				return;
			}
		}
	}

	if ($function eq 'compare') {
		return DateTime->compare_ignore_floating($from_dt, $to_dt);
	} elsif ($function eq 'compose') {
		# build date time object out of individual parameters
		my %dthash = ( locale => $locale );

		for (qw(year month day hour minute second)) {
			if (exists $opt->{$_}) {
				$dthash{$_} = $opt->{$_};
			}
		}

		$from_dt = new DateTime(%dthash);
		
		if ($fmt) {
			return $from_dt->strftime($fmt);
		} else {
			return $from_dt;
		}
	} elsif ($function eq 'diff') {
		my $duration;
		
		unless ($to_dt) {
			if ($from_now) {
				$Tag->error({name => 'to', 
					set => errmsg('missing to date for diff')});
				return;
			} else {
				$to_dt = DateTime->now(%now_hash);
			}
		}

		if ($scope eq 'days') {
			if ($duration = $from_dt->delta_days($to_dt)) {
				return $duration->weeks * 7 + $duration->days;
			} else {
				return 0;
			}
		} elsif ($scope eq 'minutes') {
			my $cmp;

			# determine first whether difference is positive or negative
			unless ($cmp = DateTime->compare($from_dt, $to_dt)) {
				return 0;
			}

			if ($duration = $from_dt->delta_ms($to_dt)) {
				return $cmp * $duration->hours * 60 + $duration->minutes;
			} else {
				return 0;
			}
		} else {
			$duration = $from_dt->subtract_datetime($to_dt);
		}
	} elsif ($function eq 'sub' || $function eq 'add') {
		my $duration;
		my $amount = $to;

		if ($function eq 'sub') {
			$amount = - $to;
		}

		if ($scope eq 'days') {
			$from_dt->add(days => $amount);
		} elsif ($scope eq 'business_days') {	
			my $incr;

			if ($function eq 'sub') {
				$incr = -1;
			}
			else {
				$incr = 1;
			}

			while($amount){
				$from_dt->add(days => $incr);
				if($from_dt->day_of_week() < 6){
					$amount -= $incr;
				}
			}
		} elsif ($scope eq 'weeks') {
			$from_dt->add(weeks => $amount);
		} elsif ($scope eq 'months') {
			$from_dt->add(months => $amount);
		} elsif ($scope eq 'years') {
			$from_dt->add(years => $amount);
		}

		if ($fmt) {
			return $from_dt->strftime($fmt);
		} else {
			return $from_dt;
		}
	} elsif ($function eq 'list') {	
		my ($daily, $span, @list, $duration, $days, $month_limit, $month_mult, $month_max);

		# daily is default scope
		$scope ||= 'day';

		unless ($from_dt) {
			$Tag->error({name => 'from', 
						set => errmsg('missing from date for diff')});
			return;
		}

		unless ($to_dt) {
			$Tag->error({name => 'to', 
						set => errmsg('missing to date for diff')});
			return;
		}

		$month_limit = $::Limit->{datetime_list} || 24;

		if ($scope eq 'year') {
			$daily = DateTime::Event::Recurrence->yearly();
			$month_mult = 365;
		} elsif ($scope eq 'month') {
			$month_mult = 30;
			$daily = DateTime::Event::Recurrence->monthly();
		} elsif ($scope eq 'week') {
			$month_mult = 7;
			$daily = DateTime::Event::Recurrence->weekly();
		} elsif ($scope eq 'day') {
			$month_mult = 1;
			$daily = DateTime::Event::Recurrence->daily();
		} else {
			$Tag->error({name => 'datetime',
						 set => errmsg('invalid scope for list function')});
			return;
		}

		# sanity check
		$duration = $to_dt->subtract_datetime($from_dt);

		if ($duration->is_negative()) {			
			$Tag->error({name => 'datetime',
						 set => sprintf('dates %s and %s are in the wrong order',
										$from_dt->strftime('%Y%M%D'),
										$to_dt->strftime('%Y%M%D'))});
			return;
		}

		$month_max = $month_limit * $month_mult;

		if ($duration->in_units('months') > $month_max) {
			$Tag->error({name => 'datetime',
						 set => sprintf('Exceeded maximum for list in months: %d', 
							$month_max)});
			return;
		}
	
		@list = $daily->as_list(start => $from_dt, end => $to_dt);

		if ($fmt) {
			@list = map {$_->strftime($fmt)} @list;
		}

		return wantarray ? @list : join(' ', @list);
	} elsif ($function eq 'month') {
		return $from_dt->month();
	} elsif ($function eq 'weekday') {
		return $from_dt->day_of_week();
	} elsif ($function eq 'year') {
		return $from_dt->year();
	}

    # apply format if provided
    if ($fmt) {
        return $from_dt->strftime($fmt);
    }

	# just return DateTime object when called without function
	return $from_dt;
}
EOR

CodeDef datetime OrderCheck 1
CodeDef datetime Routine <<EOR
sub {
	my ($ref, $name, $value, $code) = @_;	
	my ($function, $cmp, $ret);

	use vars qw/$CGI/;

	if ($code =~ s/(\w+)(:+(\w+))?\s*//) {
		$function = $1;
	} else {
		$function = 'check';
	}

	$cmp = Vend::Interpolate::filter_value('date_change', $CGI->{$3});

	if ($function eq 'check') {
		unless ($Tag->datetime('check', '', $value)) {
			return (0, $name, "invalid date '$value'");
		}
		return (1, $name);
	}

	$ret = $Tag->datetime('compare', '', $value, $cmp);

	unless (defined $ret) {
		if ($Session->{errors}->{from}) {
			return (0, $name, errmsg("Invalid date(s) %s", $value));
		}
		return (0, $name, errmsg("Invalid date(s) %s", $cmp));
	}

	if ($function eq 'after') {
		if ($ret == 1) {
			return (1, $name);
		} else {
			return (0, $name, errmsg("Date %s must be after %s", $value, $cmp));
		}
	}

	if ($function eq 'notbefore') {
		if ($ret >= 0) {
			return (1, $name);
		} else {
			return (0, $name, errmsg("Date %s is before %s", $cmp, $value));
		}
	}

}
EOR
