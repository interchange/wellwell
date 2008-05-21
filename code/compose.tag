UserTag compose Order template
UserTag compose HasEndTag
UserTag compose AddAttr
UserTag compose Routine <<EOR
sub dots2hash {
	my ($h, $v, @k) = @_;
	while (@k > 1) {
		$h = $h->{shift @k} = {};
	}
	$h->{shift @k} = $v;
}

sub {
	my ($template, $opt, $body) = @_;
	my ($template_file);

	$opt->{body} ||= $body;

	if( !$Variable->{MV_TEMPLATE_DIR} ){
		::logError("MV_TEMPLATE_DIR is not set. [compose] cannot function properly without this variable.");
	}

	if( !$Variable->{MV_COMPONENT_DIR} ){
		::logError("MV_COMPONENT_DIR is not set. [compose] cannot function properly without this variable.");
	}

	# locate template
	$template ||= $Tag->control('template', 'main');
	$template_file = "$Variable->{MV_TEMPLATE_DIR}/$template";

	# read template
	$template_file = $Tag->file($template_file);

	# process attributes ([compose attributes.COMPONENT.OPTION='VALUE'...])
	# COMPONENT => filename in components/
	# OPTION/VALUE => arbitrary option/value
	my (%attributes);

	if (ref($opt->{attributes}) eq 'HASH') {
		# Interchange's parser splits up only one level of dots, so
		# attributes.foo.bar = "com" ends up as foo.bar => com.
		# We need arbitrary levels.

		for my $k (keys %{$opt->{attributes}}) {
			dots2hash(\%attributes, $opt->{attributes}->{$k}, split /\./, $k);
		}
	}

	# override attributes from CGI variables
	# for example: mv_attribute=htmlhead.title=Homepage
	
	if ($CGI->{mv_attribute}) {
		for (@{$CGI_array->{mv_attribute}}) {
			if (/^(.+?)\.(.+?)=(.*)$/) {
				$attributes{$1}->{$2} = $3;
			}
		}
	}

	# process components ([compose components.placeholder='COMP_SPEC'...])
	# placeholder => "{NAME}" within template file
	# COMP_SPEC => "component1=alias1 c2=a2, c3 c4, c5"
	my ($components_file, $component_attributes);

	if (ref($opt->{components}) eq 'HASH') {
		for (keys %{$opt->{components}}) {
			my (@components, @content);

			if ($_ eq 'body' && $CGI->{mv_components}) {
				# override components 
				@components = split(/[,\s]+/, $CGI->{mv_components});
			} elsif (ref($opt->{components}->{$_}) eq 'ARRAY') {
				@components = @{$opt->{components}->{$_}};
			} else {
				@components = split(/[,\s]+/, $opt->{components}->{$_});
			}

			for my $comp (@components) {
				my (%var);
				# TODO support multiple aliases
				my ($name, $alias) = split(/=/, $comp, 2);

				$component_attributes = { 
					$attributes{$name} ? %{$attributes{$name}} : (),
					$attributes{$alias} ? %{$attributes{$alias}} : (),
				};

				# temporarily assign variables for component attributes
				for my $attr (keys %$component_attributes) {
					if (exists $Variable->{uc($attr)}) {
						$var{uc($attr)} = $Variable->{uc($attr)};
					}
					$Variable->{uc($attr)} = $component_attributes->{$attr};
				}

				# locate component
				$components_file = "$Variable->{MV_COMPONENT_DIR}/$name";

				# figure out whether to output class= or id=
				my $type = $attributes{$alias||$name}{css_type} || 'class';

				# add component	
				if (exists $attributes{container}
					&& $attributes{container} eq '') {
					push (@content, $Tag->include($components_file));
				} else {
					push (@content,
						qq{<div $type='$name'>} .
					    ( $alias ? qq{<div $type='$alias'>} : '' ) .
					    $Tag->include($components_file) .
					    ( $alias ? qq{</div>} : '' ) .
					    q{</div>});
				}

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
