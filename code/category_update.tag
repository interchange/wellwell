UserTag category_update AddAttr
UserTag category_update Routine <<EOR
sub {
	my ($opt) = @_;
	my ($sku, $type, @category);

	$sku = $opt->{sku};
	$type = $opt->{type};

	if (ref $opt->{category} eq 'ARRAY') {
		@category = @{$opt->{category}};
	}
	elsif ($opt->{category}) {
		$category[0] = $opt->{category};
	}

	$Tag->perl({tables => 'product_categories'});

	my ($set, %oldcats, $code, $instr);

	# get existing categories
	$set = $Db{product_categories}->query(q{select category from product_categories where sku = '%s' and type = '%s'}, $sku, $type);
	for (@$set) {
		$oldcats{$_->[0]} = 1;
	}
	
	# determine new categories
	for (@category) {
		$code = $Tag->category_master($_, $code, $type);
	}	

	if ($code) {
		delete $oldcats{$_->[0]};

		$Db{product_categories}->query(qq{insert into product_categories values('%s', %s, '%s')}, $sku, $code, $type);
	}

	# delete categories which are no longer used
	if (keys %oldcats) {
		$instr = join(',', keys %oldcats);

		$Db{product_categories}->query(qq{delete from product_categories where sku = '$sku' and category in ($instr)});
	}
}
EOR
