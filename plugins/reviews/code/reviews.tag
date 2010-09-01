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
		my $perm;

		if ($Session->{username} =~ /^(\d+)$/) {
			$review{uid} = $Session->{username};
		}
		else {
			$review{uid} = 0;
		}

		$review{created} = $Tag->time({body => '%Y-%m-%d %H:%M:%S'});

		for (qw/sku rating review/) {
			$review{$_} = $Values->{$_};
		}
		for (qw/name title/) {
			$review{$_} = $Values->{$_} || '';
		}

		$perm = $Tag->acl({function => 'check',
						   permission => ['enter_reviews_without_approval', 'enter_reviews']});

		if ($perm eq 'enter_reviews_without_approval') {
			$review{public} = 1;
		}
		
		$code = $Db{reviews}->set_slice('', %review);

		# calculate average rating
		if ($review{public}) {
			$ret = $Db{products}->query(q{update products set rating = (select sum(rating)/count(rating) from reviews where sku = '%s' and public is TRUE) where sku = '%s'}, $review{sku}, $review{sku});
		}

		return $code;
	}
	elsif ($function eq 'display') {
		my ($rating, @out, %img);

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

		for (qw/empty full/) {
			$img{"rating_path_$_"} = $opt->{"img_rating_$_"} || $Variable->{'REVIEWS_IMG_RATING_' . uc($_)};
			if ($img{"rating_path_$_"} =~ m%^/%) {
				$img{"rating_$_"} = $img{"rating_path_$_"};
			} else {
				$img{"rating_$_"} = $Config->{ImageDir} . 'reviews/' . $img{"rating_path_$_"};
			}
		}	
		
		for (1 .. $Variable->{REVIEWS_MAX_RATING}) {
			if ($rating >= $_) {
				push @out, qq{<img src="$img{'rating_full'}">};
			}
			else {
				push @out, qq{<img src="$img{'rating_empty'}">};
			}
		}
		
		return(join('', @out));
	}
	elsif ($function eq 'init') {
		# set defaults for the review form
		$Values->{sku} = $sku || $Scratch->{sku};

		$Values->{rating} = 0;

		for (qw/title review/) {
			$Values->{$_} = '';
		}

		if ($Session->{logged_in}) {
			$Values->{name} = $Tag->uc_attr_list({hash => $Values,
												  body => $Variable->{REVIEWS_DISPLAY_NAME}});
		}
	}
	elsif ($function eq 'list') {
		my $sql = qq{select title,name,review,rating,created,uid from reviews where sku = '$sku' and public is TRUE};

		# sorting reviews
		if ($opt->{sort} eq 'rating') {
			$sql .= ' order by rating desc';
		}
		elsif ($opt->{sort} eq 'created') {
			$sql .= ' order by created desc';
		}
		elsif ($opt->{sort} eq 'name') {
			$sql .= ' order by name asc'; 
		}

		return $Tag->query ({sql => $sql, list => 1, prefix => $opt->{prefix} || 'item',
			body => $body});
	}
}
EOR

