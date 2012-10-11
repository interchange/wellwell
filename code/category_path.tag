UserTag category_path Order code
UserTag category_path AddAttr
UserTag category_path Routine <<EOR
sub {
    my ($code, $opt) = @_;
    my ($parent, @path, $joiner, $table);

    return () unless $code;

    $table = $Variable->{CATEGORY_TABLE} || 'categories';

    $Tag->perl({tables => $table});

    $path[0] = $code;

    while ($parent = $Db{$table}->field($code, 'parent')) {
		unshift(@path, $parent);
		$code = $parent;
		
		# avoid infinite loop
		last if @path > 5;
    }

    if ($opt->{showname}) {
   		my @names;

		for (@path) {
			push(@names, $Db{$table}->field($_, 'name'));
		}

		if (ref $opt->{filter} eq 'ARRAY') {
			for (my $i = 0; $i < @names; $i++) {
				if ($opt->{filter}[$i]) {
					$names[$i] = $Tag->filter($opt->{filter}[$i], $names[$i]);
				}
			}
		} 
		elsif ($opt->{filter}) {
			@names = map {$Tag->filter($opt->{filter}, $_)} @names;
		}

		if ($opt->{showuri}) {
			my $uri;

			for (my $i = 0; $i < @path; $i++) {
				my $uri;

				$uri = $Tag->area($Db{$table}->field($path[$i], 'uri'));
				
				$names[$i] = qq{<a href="$uri">$names[$i]</a>};
			}
		}

		@path = @names;
	}

	if ($opt->{prefix}) {
		unshift(@path, $opt->{prefix});
	}

    if (wantarray()) {
        return @path;
    } else {
      	$joiner = $opt->{joiner} || ' ';
        return join($joiner, @path);
    }
}
EOR
