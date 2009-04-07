UserTag form Order name
UserTag form AddAttr
UserTag form Routine <<EOR
sub {
	my ($name, $opt) = @_;
	my ($form_name, @out_title, @out, @out_fields, @out_end, $required_fields);

	$Tag->perl({tables => 'form_series form_components form_elements form_attributes', subs => 1});

	$form_name = $opt->{part};

	if ($name) {
		# produce one form out of a series
		my ($set, $back, $pos, $pos_max);

		$set = $Tag->form_list($name);
		
		# ensure that we don't run out of the form series
		$pos_max = @$set;

		unless (ref($Session->{form_series}) eq 'HASH') {
			$Session->{form_series} = {};
		}

		if ($CGI->{form_series_jump}) {
			my @line = grep {$_->{part} eq $CGI->{form_series_jump}} @$set;

			if (@line) {
				if ($line[0]->{position} < $Session->{form_series}->{$name}) {
					# backward jumps are fine
					$back = $Session->{form_series}->{$name} - $line[0]->{position} - 1;
				}
				else {
					# ignore invalid jump
					Log ("Invalid jump to $CGI->{form_series}->{$name} detected.");
				}
			}
			else {
				# ignore invalid jump
				Log ("Invalid jump to $CGI->{form_series}->{$name} detected.");
			}

			# clear jump target
			delete $CGI->{form_series_jump};
		} elsif ($CGI->{series} eq $name) {
			if ($Session->{form_series}->{$name} <= $pos_max) {
				$Session->{form_series}->{$name} += 1;
			}
		} else {
			$Session->{form_series}->{$name} = 1;
		}

		# request to move back (button or image)
		if ($CGI->{series_back}) {
			$back = 1;
		}
		elsif ($CGI->{'series_back.x'}) {
			$back = 1;
		}

		if (defined $back) {
			if ($Session->{form_series}->{$name} > $back + 1) {
				$Session->{form_series}->{$name} -= $back + 1;
				$back = 1;
			} else {
				$back = 0;
			}
		}

		$pos = $Session->{form_series}->{$name};

		# always update value space first
		$Tag->update('values');

		for (@$set) {
			if ($_->{position} == $pos - 1) {
				next if $back;

				if ($_->{profile} && ! $back) {
					unless ($Tag->run_profile({name => $_->{profile}, cgi => 1})) {
						$Session->{form_series}->{$name} -= 1;
						$Tag->tmp('series_part', $_->{part});
						return $Tag->form({series => $name, 
							label => $_->{label},
							part => $_->{part}, 
							template => $opt->{template} || $_->{template}});
					}
				}
				# check for appropriate hook for saving
				my ($hook, $hooksub, $hookret);

				$hook = join('_', 'form', $name, 'save');
				$hooksub = $Config->{Sub}{$hook};

				if ($hooksub) {
					$hookret = $hooksub->($_->{part});

					if ($hookret->{page}) {
						$CGI->{mv_nextpage} = $hookret->{page};
						if ($hookret->{jump}) {
							$CGI->{form_series_jump} = $hookret->{jump};
						}
						return;
					}
				}
				else {
					Log("Hook $hook not found.");
				}
			} 
			elsif ($_->{position} == $pos) {
				# check for appropriate hook for loading
				my ($hook, $hooksub, $hookret);

				$hook = join('_', 'form', $name, 'load');
				$hooksub = $Config->{Sub}{$hook};

				if ($hooksub) {
					$hookret = $hooksub->($_->{part});

					if ($hookret && $hookret->{page}) {
						$Tag->tmp('form_series_bounce', $hookret->{page});
						return;
					}
				}
				else {
					Log("Hook $hook not found.");
				}

				$Tag->tmp('series_part', $_->{part});
				return $Tag->form({series => $name, label => $_->{label},
					part => $_->{part},
					template => $opt->{template} || $_->{template}});
			}
		}

		$Tag->error({name => 'form', set => "Missing form $name, position $pos"});
		return;
	}

		push(@out_title, theme('form_title', $opt->{part}, $opt->{label}, $opt));

		if ($opt->{prepend}) {
			push(@out_title, $opt->{prepend});
		}
	
		# form elements
		my ($elset, $attrset, $qcomp);

		$qcomp = $Db{form_elements}->quote($opt->{part});

		$elset = $Db{form_elements}->query({sql => qq{select name,label,widget from form_elements where component = $qcomp order by priority desc, code asc}, hashref => 1});

		for my $elref (@$elset) {
			# fetch attributes for form element
			my (%attributes, $required);
		
			$attrset = $Db{form_attributes}->query(q{select attribute,value from form_attributes where name = '%s' and (component = '' or component = '%s') order by component asc}, $elref->{name}, $opt->{part});
			for (@$attrset) {
				$attributes{$_->[0]} = $_->[1];
			}

			# determine current value
			my $value = $Values->{$elref->{name}};

			# "display" form element
			my $label = '';
			my $append = '';
		
			if (delete $attributes{profile} eq 'required') {
				$append = q{<span class="required">*</span>};
				$required = 1;
				$required_fields++;
			}

			if ($elref->{label} =~ /\S/) {
				$label = "$elref->{label}$append$opt->{appendlabel}";
			}

			my $error = $Tag->error({name => $elref->{name},
				show_error => 1});

			push (@out_fields, theme('form_element', $elref->{name}, $label,
				   	$elref->{widget} || 'text',
					$value,
					{class => $required ? 'required' : '',
					form_name => $form_name,
					error => $error,
					%attributes}));

		}

		push(@out_end, '</fieldset>');

	unless (@$elset) {
		@out = ();
	}

	unless ($opt->{partial}) {
		my ($out, $url, $action, $sid, $series, $body, $page);

		# read template
		my ($t_name, $t_file, $t_template);

		$t_name = $opt->{template} || 'form';
		$t_file = "$Variable->{MV_TEMPLATE_DIR}/$t_name";
		
		unless ($t_template = $Tag->file($t_file)) {
			$Tag->error({name => 'form_template',
				set => "Invalid template $t_name"});
			return;
		}

		# read components
		my (%fhash, $set, $content);

		$set = $Db{form_components}->query(q{select component,location from form_components where name = '%s' and (part = '%s' or part = '') order by priority desc}, $opt->{series}, $opt->{part});

		for (@$set) {
			$content = $Tag->include("$Variable->{MV_COMPONENT_DIR}/$_->[0]");
			$fhash{$_->[1]} .= $content;
		}

		if ($opt->{page}) {
			$page = $opt->{page};
		}
		elsif ($CGI->{mv_nextpage}) {
			$page = $CGI->{mv_nextpage};
		}
		else {
			$page = substr($Session->{last_url},1);
		}

		$action = $Tag->area({href => $page,
							  match_security => 1});
		$sid = $Tag->form_session_id();

		if ($opt->{series}) {
			$series = qq{<input type="hidden" name="series" value="$opt->{series}">
};	
		}

		@out = (@out_title, @out_fields, @out_end);

		$fhash{top} = <<EOT;
<form action="$action" method="post" name="$form_name">
$series$sid
EOT

		$fhash{title} = join("\n", @out_title);
		$fhash{fields} = join("\n", @out_fields);
		$fhash{end} = join("\n", @out_end);

		$fhash{body} .= join("\n", @out);

		$fhash{submit} = theme('form_submit', $opt->{series}, $form_name);
		$fhash{bottom} = q{</form>};

		$fhash{required} = $required_fields;

		$out = $Tag->uc_attr_list({hash => \%fhash, body => $t_template});

		return $out;
	}
	
	return join("\n", @out);
}
EOR
