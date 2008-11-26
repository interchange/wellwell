UserTag reviews Order function sku
UserTag reviews HasEndTag
UserTag reviews Routine <<EOR
sub {
	my ($function, $sku, $body) = @_;
	my (%review, $ret, $code);

	$Tag->perl({tables => 'products reviews'});
	$Tag->update('values');

	$sku ||= $CGI->{reviews_sku};

	if ($function eq 'create') {
		$review{uid} = $Scratch->{uid} || 0;
		$review{created} = $Tag->time({body => '%Y-%m-%d %H:%M:%S'});

		for (qw/sku rating title review/) {
			$review{$_} = $Values->{$_};
		}

		$code = $Db{reviews}->set_slice('', %review);

		# calculate average rating
		$ret = $Db{products}->query(q{update products set rating = (select sum(rating)/count(rating) from reviews where sku = '%s') where sku = '%s'}, $sku, $sku);

		return $code;
	} elsif ($function eq 'list') {
		my $sql = qq{select title,review,rating,created,uid from reviews where sku = '$sku'};
		return $Tag->query ({sql => $sql, list => 1, prefix => 'item',
			body => $body});
	}
}
EOR

