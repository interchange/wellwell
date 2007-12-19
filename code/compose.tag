UserTag compose Order template
UserTag compose HasEndTag
UserTag compose AddAttr
UserTag compose Routine <<EOR
sub {
	my ($template, $opt, $body) = @_;
	my ($template_file);

	$opt->{body} ||= $body;

	# locate template
	$template ||= $Tag->control('template', 'main');
	$template_file = "$Variable->{MV_TEMPLATE_DIR}/$template";

	# read template
	$template_file = $Tag->file($template_file);

	# process attributes
	my (%attributes);

	if (ref($opt->{attributes}) eq 'HASH') {
		# Interchange's parser splits up only one level of dots, so
		# attributes.foo.bar = "com" ends up as foo.bar => com.
		# We need to split completely, though.
		my (@frags);

		for (keys %{$opt->{attributes}}) {
			@frags = split(/\./, $_);
		
			if (@frags == 2) {
				$attributes{$frags[0]}->{$frags[1]} = $opt->{attributes}->{$_};
			}
		}
	}

	# process components
	my ($components_file, $component_attributes);

	if (ref($opt->{components}) eq 'HASH') {
		for (keys %{$opt->{components}}) {
			my (@components, @content);

			if ($_ eq 'body' && $CGI->{mv_components}) {
				# override components 
				@components = split(/[,\s]/, $CGI->{mv_components});
			} else {
				@components = split(/[,\s]/, $opt->{components}->{$_});
			}

			for my $comp (@components) {
				my (%var);
				my ($name, $alias) = split(/=/, $comp, 2);

				$component_attributes = $attributes{$name};

				# temporarily assign variables for component attributes
				for my $attr (keys %$component_attributes) {
					if (exists $Variable->{uc($attr)}) {
						$var{uc($attr)} = $Variable->{uc($attr)};
					}
					$Variable->{uc($attr)} = $component_attributes->{$attr};
				}

				# locate component
				$components_file = "$Variable->{MV_COMPONENT_DIR}/$name";

				# add component	
				push (@content, qq{<div class="$name">} .
								$Tag->include($components_file) . q{</div>});

				# reset variables
				for my $attr (keys %$component_attributes) {
					if (exists $var{uc($attr)}) {
						$Variable->{uc($attr)} = $var{uc($attr)};
					} else {
						delete $Variable->{uc($attr)};
					}
				}
			}

			$opt->{$_} = join('', @content);
		}
	}

	# compose
	$Tag->uc_attr_list({hash => $opt, body => $template_file});	
}
EOR
