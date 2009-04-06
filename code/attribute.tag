UserTag attribute Order function component name value
UserTag attribute AddAttr
UserTag attribute Routine <<EOR
sub {
	my ($function, $component, $name, $value) = @_;
	my $attval;

	if ($function eq 'set') {
		if ($component) {
			$attval = "$component.$name=$value";
		}
		else {
			$attval = "$name=$value";
		}

		push(@{$CGI_array->{mv_attribute}}, $attval);

		$CGI->{mv_attribute} = join("\0", @{$CGI_array->{mv_attribute}});
	}

	return 1;
}
EOR
