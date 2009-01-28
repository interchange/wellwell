UserTag content Order function code
UserTag content AddAttr
UserTag content Routine <<EOR
sub {
	my ($function, $code, $opt) = @_;
	my ($ctref, $out);

	$Tag->perl({tables => 'content'});

	if ($opt->{uri}) {
		my ($ctset, $uri_qt);

		$uri_qt = $Db{content}->quote($opt->{uri});

		$ctset = $Db{content}->query({sql => qq{select * from content where uri = $uri_qt},
			hashref => 1});
			
		if (@$ctset) {
			$code = $ctset->[0]->{code};
			$ctref = $ctset->[0];
		} else {
			$Tag->error({name => 'content',
					set => 'Content not found'});
			return '';
		}
	} 
	else {
		unless ($ctref = $Db{content}->row_hash($code)) {
			Log("Code $code not found.");
			$Tag->error({name => 'content',
						set => 'Content not found'});
			return '';
		}
	}

	if ($opt->{edit_link}) {
		my (@edit_perms, $uri);

		# determine whether uses has permissions to edit content
		@edit_perms = ('edit_content');

		if ($Session->{logged_in} && $Session->{username} == $ctref->{uid}) {
			push (@edit_perms, 'edit_own_content');
		}

		if ($Tag->acl({function => 'check', permission => \@edit_perms})) {
			$uri = $Tag->area({href => "content/edit/$ctref->{code}"});
			$out .= qq{<a href="$uri">Edit</a>};
		}
	}

	unless ($opt->{no_title}) {
		$out .= $ctref->{title};
	}

	$out .= $ctref->{body};
	return $out;
}
EOR
