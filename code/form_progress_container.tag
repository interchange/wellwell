UserTag form_progress_container Order name
UserTag form_progress_container AddAttr
UserTag form_progress_container HasEndTag
UserTag form_progress_container Routine <<EOR
sub {
	my ($name, $opt, $body) = @_;
	my ($name_qtd, $sql, @results, $position, $forms, $content);

	@results = $Tag->form_list($name);
	$position = $Session->{form_series}->{$name} || 1;
	$forms = scalar(@{$results[0]}) || 1;

	$Tag->tmp('progress_slice_width', int(1 / $forms * 100));
	$Tag->tmp('progress_percent_width', int($position / $forms * 100));
	$Tag->tmp('progress_forms', $forms);

	if ($forms > 1 && $opt->{links}) {
		my ($showlinks, $partpos, $curpart);

		$showlinks = 1;
		$partpos = $results[1]->{part};

		# for some parts links might not be appropriate (e.g. receipt)
		if ($opt->{parts_without_links}) {
			$curpart = $results[0]->[$position - 1]->[$partpos];
			if (grep {$curpart eq $_} split(/\s*,\s*/, $opt->{parts_without_links})) {
				$showlinks = 0;
			}
		}

		if ($showlinks) {
			push(@results, 'progress_url');
			$results[1]->{progress_url} = scalar(@results) - 3;

			for (my $i = 0; $i < $forms; $i++) {
				if ($i < $position - 1) {
					push (@{$results[0]->[$i]}, $Tag->area({href => $name,
						form => "form_series_jump=$results[0]->[$i]->[$partpos]"}));
				}
				push (@{$results[0]->[$i]}, '');
			}
		}
	}	

	$content = $Tag->loop({object => {
			mv_results => $results[0],
			mv_field_hash => $results[1]
		},
		prefix => 'item',
		body => $body}
	);

	return $content;
}
EOR
