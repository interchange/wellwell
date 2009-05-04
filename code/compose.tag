UserTag compose Order template
UserTag compose HasEndTag
UserTag compose AddAttr
UserTag compose Routine <<EOR
sub dots2hash {
	my ($h, $v, @k) = @_;
	my ($skey);

	while (@k > 1) {
		$skey = shift @k;
		$h->{$skey} ||= {};
		$h = $h->{$skey};
	}
	$h->{shift @k} = $v;
}

sub {
	my ($template, $opt, $body) = @_;
	my (%acl, %forms, $template_file);

	if ($opt->{acl})  {
		# check permissions first
		for my $k (keys %{$opt->{acl}}) {
			dots2hash(\%acl, $opt->{acl}->{$k}, split /\./, $k);
		}

		unless ($Tag->acl('check', $acl{check})) {
			$Tag->deliver({location => $Tag->area($acl{bounce}),
				status => '302 move temporarily'});
			return;							
		}
	}

	if ($opt->{forms}) {
		# process forms first
		for my $k (keys %{$opt->{forms}}) {
			dots2hash(\%forms, $opt->{forms}->{$k}, split /\./, $k);
		}

		my $name;

		for my $k (keys %forms) {
			$name = $forms{$k}->{name};

			if ($Scratch->{forms}->{$name}) {
				# form intercepted by autoload
				$forms{$k}->{content} = $Scratch->{forms}->{$name};
			} else {
				$forms{$k}->{content} = $Tag->form({name => $name,
					template => $forms{$k}->{template}});
			}
		}

		# form bounce to another page
		if ($Scratch->{form_series_bounce}) {
			$Tag->deliver({location => $Tag->area($Scratch->{form_series_bounce}), status => '302 move temporarily'});
			return;
		}
	}

	$opt->{body} ||= $body;
	# preserve local body even after components.body=, as user might want it
	$opt->{local_body} = $opt->{body};

	if( !$Variable->{MV_TEMPLATE_DIR} ){
		::logError("MV_TEMPLATE_DIR is not set. [compose] cannot function properly without this variable.");
	}

	if( !$Variable->{MV_COMPONENT_DIR} ){
		::logError("MV_COMPONENT_DIR is not set. [compose] cannot function properly without this variable.");
	}

	unless( $template_file = $opt->{template_file} ) {
		# locate template
		$template ||= $Tag->control('template', 'main');
		$template_file = "$Variable->{MV_TEMPLATE_DIR}/$template";

		# read template
		$template_file = $Tag->file($template_file);
	}

	# process attributes ([compose attributes.COMPONENT.OPTION='VALUE'...])
	# COMPONENT => filename in components/
	# OPTION/VALUE => arbitrary option/value
	my (%attributes);

	# automatic attributes
	if ($Variable->{MV_ATTRIBUTE_AUTO}) {
		my @auto = split(/\s+/, $Variable->{MV_ATTRIBUTE_AUTO});

		for (@auto) {
			my ($ph, $c) = split(/[=:]/, $_, 2);
			dots2hash(\%attributes, $c, split /\./, $ph);
		}
	}

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

	# automatic components
	if ($Variable->{MV_COMPONENT_AUTO}) {
		my @auto = split(/\s+/, $Variable->{MV_COMPONENT_AUTO});

		for (@auto) {
			my ($ph, $c) = split(/[=:]/, $_, 2); # i.e. body=c1,c2=a2

			for my $sc (reverse split(/,+/, $c)) {
				if (exists $opt->{components}->{$ph}) {
					$opt->{components}->{$ph} = "$sc $opt->{components}->{$ph}";
				} else {
						$opt->{components}->{$ph} = $sc;
				}
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

				if ($forms{$comp}) {
					# use precalculated form
					push(@content, $forms{$comp}->{content});
					next;
				}

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

				# figure out whether to output class= or id=
				my $type = $attributes{$alias||$name}{css_type} || 'class';

				# locate component
				$components_file = "$Variable->{MV_COMPONENT_DIR}/$name";

				# add component	
				my $component_content;

				if ($_ eq 'body' and $name eq 'local_body' ) {
					$component_content = $opt->{local_body};
				} else {
					$component_content =  $Tag->include($components_file);

					unless (defined $component_content && $name ne 'local_body') {
						Log("Component $name from $components_file not found");
						$Tag->error({name => 'component', set => "Component $name not found."});
					}
				}

				if ($component_content =~ /\S/
					|| ! $component_attributes->{skipblank}) {
					if (exists $component_attributes->{container}
						&& $component_attributes->{container} eq '') {
						push (@content, $component_content);
					} else {
						push (@content,
							qq{<div $type='$name'>} .
					    	( $alias ? qq{<div $type='$alias'>} : '' ) .
						    $component_content .
						    ( $alias ? qq{</div>} : '' ) .
						    q{</div>});
					}
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
