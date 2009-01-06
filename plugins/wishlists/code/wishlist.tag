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

	if ($function eq 'create') {
		my $pref;

		$pref = $Db{products}->row_hash($sku);

		# check whether product is valid
		unless ($pref && ! $pref->{inactive}) {
			$Tag->error({name => $sku, set => 'Product discontinued.'});
			return;
		}

		# check whether wishlist exists
		my ($qname, $set, $code);

		$qname = $Db{carts}->quote($name);

		$set = $Db{carts}->query(qq{select code from carts where uid = $Session->{username} and name = $qname}); 

		if (@$set) {
			$code = $set->[0]->[0];
		}
		else {
			$code = $Db{carts}->autosequence();
			$Db{carts}->set_slice($code, uid => $Session->{username},
								created => time(),
								name => $name);
		}

		# add product to wishlist
		$Db{cart_products}->set_slice([$code, $sku], {position => 0});
	}
	elsif ($function eq 'list') {
		# check whether wishlist exists
		my ($qname, $set, $code);

		$qname = $Db{carts}->quote($name);

		$set = $Db{carts}->query(qq{select code from carts where uid = $Session->{username} and name = $qname}); 

		if (@$set) {
			$code = $set->[0]->[0];
			my $sql = qq{select sku from cart_products where cart = $code order by position};
			return $Tag->query ({sql => $sql, list => 1, prefix => 'item',
				body => $body});
		}
		else {
			$Tag->error("Wishlist is missing.");
		}
	}
}
EOR
