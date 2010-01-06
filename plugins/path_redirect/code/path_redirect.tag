UserTag path_redirect Order function source target
UserTag path_redirect AddAttr
UserTag path_redirect Routine <<EOR
sub {
	my ($function, $source, $target, $opt) = @_;
	my (%update_mode, %redirect, $ret);

	$Tag->perl({tables => 'path_redirect'});

	%update_mode = (add => 'insert', modify => 'update', set => 'upsert');

	if (exists $update_mode{$function}) {
		# in case target exists we have to rewrite it
		$Db{path_redirect}->query(q{update path_redirect set path_target = '%s' where path_target = '%s'},
			$target, $source);

		# collect data for redirect
		$redirect{path_source} = $source;
		$redirect{path_target} = $target;

		if ($opt->{status_code}) {
			$redirect{status_code} = $opt->{status_code};
		}
		else {
			$redirect{status_code} = 301;
		}

		$Db{path_redirect}->set_slice([{dml => $update_mode{$function}}, delete $redirect{path_source}],
			\%redirect);
	}
	elsif ($function eq 'delete') {
		if ($source) {
			$ret = $Db{path_redirect}->delete_record($source);
		}
		elsif ($target) {
			$ret = $Db{path_redirect}->query(q{delete from path_redirect where path_target = '%s'}, $target);
		}
		else {
			die "Either source or path required for [path-redirect delete].";
		}
	}
	elsif ($function eq 'check') {
		my $recref;

		# check whether a redirect applies to the given path
		unless ($recref = $Db{path_redirect}->row_hash($source)) {
			return;
		}

		if ($opt->{bump}) {
			$Db{path_redirect}->set_field($source, 'last_used', $Tag->time({format => '%s'}));
		}

		return {url => $recref->{path_target}, status => $recref->{status_code}};
	}
	else {
		die "Unknown function for [path-redirect]: $function.";
	}		
}
EOR
