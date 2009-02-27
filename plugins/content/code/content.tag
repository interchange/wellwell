UserTag content Order function code
UserTag content AddAttr
UserTag content HasEndTag
UserTag content Routine <<EOR
sub {
	my ($function, $code, $opt, $body) = @_;
	my ($ctref, $out, %content, $istemplate);

	$Tag->perl({tables => 'content'});

	if ($opt->{uri}) {
		my ($ctset, $uri_qt);

		$uri_qt = $Db{content}->quote($opt->{uri});

		$ctset = $Db{content}->query({sql => qq{select * from content where uri = $uri_qt},
			hashref => 1});
		
		if (@$ctset) {
			$code = $ctset->[0]->{code};
			$ctref = $ctset->[0];
		}
	} 
	else {
		$ctref = $Db{content}->row_hash($code);
	}

	if ($ctref) {
		if ($opt->{edit_link}) {
			my (@edit_perms, $uri);

			# determine whether uses has permissions to edit content
			@edit_perms = ('edit_content');

			if ($Session->{logged_in} && $Session->{username} == $ctref->{uid}) {
				push (@edit_perms, 'edit_own_content');
			}

			if ($Tag->acl({function => 'check', permission => \@edit_perms})) {
				$uri = $Tag->area({href => "content/edit/$ctref->{code}"});
				$content{edit_link} = qq{<a href="$uri">Edit</a>};
			}
		}

		unless ($opt->{no_title}) {
			$content{title} = $ctref->{title};
		}

		$content{body} = $ctref->{body};
	} 
	else {
		if ($opt->{create_link}) {
			my ($uri);

			# determine whether uses has permissions to edit content
			if ($Tag->acl({function => 'check', permission => 'create_content'})) {
				$uri = $Tag->area({href => "content/edit",
					form => "uri=$opt->{uri}"});

				$content{edit_link} = qq{<a href="$uri">Create</a>};
			}
		}
	}

	# Determine whether content is a template or just text
	if (ref($opt->{params}) eq 'HASH') {
		$istemplate = 1;
	}

	if ($body) {
		if ($istemplate) {
			for (keys %{$opt->{params}}) {
				$content{$_} = $opt->{params}->{$_};
			}
		}

		return $Tag->uc_attr_list({hash => \%content, body => $body});
	}

	if ($istemplate) {
		$content{body} = $Tag->uc_attr_list({hash => $opt->{params},
			body => $content{body}});
	}

	return $content{edit_link} . $content{title} . $content{body};
}
EOR
