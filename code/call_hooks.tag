UserTag call_hooks Order name mode
UserTag call_hooks AddAttr
UserTag call_hooks Routine <<EOR
sub {
	my ($name, $mode, $opt) = @_;
	my (@plugins, @ret);

	if ($opt->{plugins}) {
		@plugins = split(/,/, $opt->{plugins});
	}
	else {
		@plugins = split(/,/, $Variable->{PLUGINS});
	}

	for my $plugin (@plugins) {
		if ($sub = $Config->{Sub}->{"${plugin}_$name"}) {
			push(@ret, $sub->($opt));
		}
	}

	if ($mode eq 'collect') {
		return @ret;
	}

	return;	
}
EOR
