UserTag reviews Order function sku
UserTag reviews HasEndTag
UserTag reviews AddAttr
UserTag reviews Routine <<EOR
sub {
	my ($function, $sku, $opt, $body) = @_;
	my (%review, $ret, $code);

	$Tag->perl({tables => 'products reviews'});
	$Tag->update('values');

	if ($function eq 'create') {
		$review{uid} = $Scratch->{uid} || 0;
		$review{created} = $Tag->time({body => '%Y-%m-%d %H:%M:%S'});

		for (qw/sku rating review/) {
			$review{$_} = $Values->{$_};
		}
		for (qw/name title/) {
			$review{$_} = $Values->{$_} || '';
		}
		
		$code = $Db{reviews}->set_slice('', %review);

		# calculate average rating
		$ret = $Db{products}->query(q{update products set rating = (select sum(rating)/count(rating) from reviews where sku = '%s') where sku = '%s'}, $review{sku}, $review{sku});

		return $code;
	}
	elsif ($function eq 'display') {
		my ($rating, @out);

		if ($opt->{rating}) {
			$rating = $opt->{rating};
		}
		else {
			$rating = $Db{products}->field($sku, 'rating');
		}

		unless ($rating) {
			if ($sku) {
				my $url = $Tag->area("reviews/$sku/create");
				return qq{<a href="$url">Enter First Review</a>};
			}
		}
		
		for (1 .. $Variable->{REVIEWS_MAX_RATING}) {
			if ($rating >= $_) {
				push @out, qq{<img src="/images/reviews/$Variable->{REVIEWS_IMG_RATING_FULL}">};
			}
			else {
				push @out, qq{<img src="/images/reviews/$Variable->{REVIEWS_IMG_RATING_EMPTY}">};
			}
		}
		
		return(join('', @out));
	}
	elsif ($function eq 'init') {
		# set defaults for the review form
		$Values->{rating} = 0;

		for (qw/title review name/) {
			$Values->{$_} = '';
		}
	}
	elsif ($function eq 'list') {
		my $sql = qq{select title,name,review,rating,created,uid from reviews where sku = '$sku'};
		return $Tag->query ({sql => $sql, list => 1, prefix => 'item',
			body => $body});
	}
}
EOR

