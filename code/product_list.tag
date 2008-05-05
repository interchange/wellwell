UserTag product_list Order category 
UserTag product_list HasEndTag 
UserTag product_list Routine <<EOR
sub {
	my ($category, $body) = @_;
	my $output;

	if ($category){
		$category = " WHERE pc.category='$category' ";
	}

	$Tag->perl( {tables => 'products product_categories'} );
	my $db = $Db{products};

	my $sql = qq{
		SELECT p.sku,p.manufacturer,p.name,p.description,p.price,p.image
		FROM products p LEFT OUTER JOIN product_categories pc
		ON p.sku=pc.sku $category
		};

	my @results = $db->query({sql => $sql, hashref => 1});

	return uneval(\@results);

	return Vend::Tags->loop({
		object => {
			mv_results => \$results,
			mv_field_names => \@field_names,
			mv_field_hash => \%field_hash
		},
		body => $body
	});
}
EOR
