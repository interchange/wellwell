UserTag wishlist Order function sku name
UserTag wishlist AddAttr
UserTag wishlist HasEndTag
UserTag wishlist Routine <<EOR
sub {
	my ($function, $sku, $name, $opt, $body) = @_;

	$function ||= 'list';
	$name ||= $Variable->{WISHLISTS_DEFAULT_NAME};

	unless ($Session->{logged_in}) {
		return;
	}

	$Tag->perl({tables => 'products carts cart_products'});

	# check whether wishlist exists
	my ($qname, $set, $wishlist_code);

	$qname = $Db{carts}->quote($name);
	$set = $Db{carts}->query(qq{select code from carts where uid = $Session->{username} and name = $qname}); 
	if (@$set) {
		$wishlist_code = $set->[0]->[0];
	}

	if ($function eq 'create') {
		my $pref;

		$pref = $Db{products}->row_hash($sku);

		# check whether product is valid
		unless ($pref && ! $pref->{inactive}) {
			$Tag->error({name => $sku, set => 'Product discontinued.'});
			return;
		}

		# create new wishlist if necessary
		unless ($wishlist_code) {
			$wishlist_code = $Db{carts}->autosequence();
			$Db{carts}->set_slice($wishlist_code, uid => $Session->{username},
								created => time(),
								name => $name);
		}

		# check whether product is within wishlist
		if ($Db{cart_products}->record_exists([$wishlist_code, $sku])) {
			$Tag->error({name => $sku, set => 'Product already in wishlist'});
			return;
		}

		# add product to wishlist
		$Db{cart_products}->set_slice([$wishlist_code, $sku], {position => 0});
		return;
	}

	unless ($wishlist_code) {
		$Tag->error({name => 'wishlist', set => 'Wishlist is missing.'});
		return;
	}

	elsif ($function eq 'remove') {
		# remove product from wishlist
		$Db{cart_products}->delete_record([$wishlist_code, $sku]);
	}
	elsif ($function eq 'list') {
		# list products from wishlist
		my $sql = qq{select sku from cart_products where cart = $wishlist_code order by position};

		return $Tag->query ({sql => $sql, list => 1, prefix => 'item',
				body => $body});
	}
}
EOR
