UserTag compose Order template
UserTag compose HasEndTag
UserTag compose AddAttr
UserTag compose Routine <<EOR
sub {
	my ($template, $opt, $body) = @_;
	my ($template_file);

	$opt->{body} ||= $body;

	# locate template
	$template_file = "templates/$template";

	# read template
	$template_file = $Tag->file($template_file);

	# process components
	my $components_file;

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
				my ($name, $alias) = split(/=/, $comp, 2);

				# locate component
				$components_file = "$Variable->{MV_COMPONENT_DIR}/$name";

				# add component	
				push (@content, qq{<div class="$name">} .
								$Tag->include($components_file) . q{</div>});
			}

			$opt->{$_} = join('', @content);
		}
	}

	# compose
	$Tag->uc_attr_list({hash => $opt, body => $template_file});	
}
EOR