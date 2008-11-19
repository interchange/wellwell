UserTag form Order name
UserTag form AddAttr
UserTag form Routine <<EOR
sub {
	my ($name, $opt) = @_;
	my @out;

	$Tag->perl({tables => 'form_elements form_attributes'});

	push(@out, '<fieldset>');

	# label for form elements
	if ($opt->{label}) {
		if ($opt->{anchor}) {
				push(@out, qq{<legend><a name="$opt->{anchor}">$opt->{label}</a></legend>});
		}
		else {
				push(@out, qq{<legend>$opt->{label}</legend>});
		}
	}

	if ($opt->{prepend}) {
		push(@out, $opt->{prepend});
	}
	
	# form elements
	my ($elset, $attrset, $qcomp);

	$qcomp = $Db{form_elements}->quote($opt->{component});

	$elset = $Db{form_elements}->query({sql => qq{select name,label,widget from form_elements where component = $qcomp order by priority desc}, hashref => 1});

	for my $elref (@$elset) {
		# fetch attributes for form element
		my %attributes;

		$attrset = $Db{form_attributes}->query(q{select attribute,value from form_attributes where name = '%s' and component = '%s'}, $elref->{name}, $opt->{component});
		for (@$attrset) {
			$attributes{$_->[0]} = $_->[1];
		}

		# determine current value
		my $value = $Tag->filter('encode_entities', $Values->{$elref->{name}});

		# "display" form element
		my $label = '';
		my $append = '';
		
		if (delete $attributes{profile} eq 'required') {
			$append = q{<span class="required">*</span>};
		}

		if ($elref->{label} =~ /\S/) {
			$label = "$elref->{label}$append$opt->{appendlabel}";
		}
		
		push (@out, qq{<label for="$elref->{name}">$label</label>});
		push (@out, $Tag->display({name => $elref->{name},
								   type => $elref->{widget} || 'text',
								   value => $value,
								   %attributes}));
		push (@out, '<br/>');
	}

	push(@out, '</fieldset>');

	unless ($opt->{partial}) {
		my ($out, $url, $action, $sid, $body);

		$action = $Tag->area({href => substr($Session->{last_url},1),
							  match_security => 1});
		$sid = $Tag->form_session_id();
		$body = join("\n", @out);
	
		$out = <<EOT;
<form action="$action" method="post">
$sid
$body
<input type="submit" name="submit" value="OK">
</form>
EOT
		return $out;
	}
	
	return join("\n", @out);
}
EOR

