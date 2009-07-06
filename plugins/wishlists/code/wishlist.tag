UserTag wishlist Order function sku name type
UserTag wishlist AddAttr
UserTag wishlist HasEndTag
UserTag wishlist Routine <<EOR
sub {
	my ($function, $sku, $name, $type, $opt, $body) = @_;
	my ($wishlist_code, $set, $status);

	$function ||= 'list';
	$name ||= $Variable->{WISHLISTS_DEFAULT_NAME};
	$type ||= $Variable->{WISHLISTS_DEFAULT_TYPE};

	unless ($Session->{logged_in}) {
		return;
	}

	$Tag->perl({tables => 'products carts cart_products'});

	if ($function eq 'carts') {
		my @carts;

		if ($opt->{passed}) {
			# produce string suitable for [display passed=]
			$set = $Db{carts}->query(qq{select code,name from carts where uid = $Session->{username} and type = '%s' order by name}, $type); 
			@carts = map {"$_->[0]=$_->[1]"} @$set;
		}
		else {
			$set = $Db{carts}->query(qq{select code from carts where uid = $Session->{username} and type = '%s' order by name}, $type); 
			@carts = map {$_->[0]} @$set;
		}

		return wantarray ? @carts : join(',', @carts);
	}

	if ($opt->{code}) {
		$wishlist_code = $opt->{code};
	} elsif ($name) {
		# lookup wishlist
		my $qname;

		$qname = $Db{carts}->quote($name);
		$set = $Db{carts}->query(qq{select code from carts where uid = $Session->{username} and name = $qname}); 
		if (@$set) {
			$wishlist_code = $set->[0]->[0];
		}
	}

	if ($wishlist_code) {
		# record wishlist status
		$status = $Db{carts}->field($wishlist_code, 'status');
	}

	# determine fields to use for wishlists
	my $i = 0;
	my %product_fields;

	for my $f (split(/\s*,\s*/, $Variable->{WISHLISTS_PRODUCTS_FIELDS})) {
		$product_fields{$f} = $i++;
	}	

	if ($function eq 'create') {
		my $pref;

		$pref = $Db{products}->row_hash($sku);

		# check whether product is valid
		unless ($pref && ! $pref->{inactive}) {
			$Tag->error({name => $sku, set => 'Product discontinued.'});
			return;
		}

		if ($wishlist_code) {			
			if ($status eq 'final') {
				# no updates allowed to finalized wishlists
				$Tag->error({name => 'wishlist', set => 'Wishlist finalized'});
				return;
			}
		}
		else {
			# create new wishlist
			$wishlist_code = $Db{carts}->autosequence();
			$Db{carts}->set_slice($wishlist_code, uid => $Session->{username},
								  created => $Tag->time({format => '%s'}),
								  type => $type,
								  name => $name);
		}

		# check whether product is within wishlist
		if ($Db{cart_products}->record_exists([$wishlist_code, $sku])) {
			$Tag->error({name => $sku, set => 'Product already in wishlist'});
			return;
		}

		# add product to wishlist
		my %data = (position => 0);

		for (keys %product_fields) {
			if (exists $opt->{$_} && $opt->{$_} =~ /\S/) {
				$data{$_} = $opt->{$_};
			}
		}

		$Db{cart_products}->set_slice([$wishlist_code, $sku], \%data);

		# update timestamp on cart
		$Db{carts}->set_field($wishlist_code, 'last_modified', $Tag->time({format => '%s'}));

		return 1;
	}

	unless ($wishlist_code) {
		$Tag->error({name => 'wishlist', set => 'Wishlist is missing.'});
		return;
	}
	
	if ($function eq 'update') {
		if ($status eq 'final') {
			# no updates allowed to finalized wishlists
			$Tag->error({name => 'wishlist', set => 'Wishlist finalized'});
			return;
		}

		# update product in wishlist
		my %data;

		for (keys %product_fields) {
			if (exists $opt->{$_} && $opt->{$_} =~ /\S/) {
				$data{$_} = $opt->{$_};
			}
		}

		$Db{cart_products}->set_slice([$wishlist_code, $sku], %data);
	}
	elsif ($function eq 'remove') {
		if ($status eq 'final') {
			# no updates allowed to finalized wishlists
			$Tag->error({name => 'wishlist', set => 'Wishlist finalized'});
			return;
		}

		# remove product from wishlist
		$Db{cart_products}->delete_record([$wishlist_code, $sku]);
	}
	elsif ($function eq 'list') {
		# list products from wishlist
		my $fields = '';

		if (keys %product_fields) {
			$fields = join(',', '', keys %product_fields);			
		}

		# expose status
		$Tag->tmp('wishlist_status', $status);

		my $sql = qq{select sku$fields from cart_products where cart = $wishlist_code order by position};

		return $Tag->query ({sql => $sql, list => 1, prefix => 'item',
				body => $body});
	}
	elsif ($function eq 'name') {
		return $Db{carts}->field($wishlist_code, 'name');
	}
	elsif ($function eq 'status') {
		my $status;

		if ($opt->{status}) {
			$Db{carts}->set_field($wishlist_code, 'status', $opt->{status});
			return;
		}

		return $status;
	}
}
EOR
