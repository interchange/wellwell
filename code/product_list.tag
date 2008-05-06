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
		SELECT p.sku,p.manufacturer,p.name,p.description,p.price
		FROM products p LEFT OUTER JOIN product_categories pc
		ON p.sku=pc.sku $category
		};

	my @results = $db->query({sql => $sql});

	return $Tag->loop({
		prefix => 'item',
		object => 
		{
			mv_results => $results[0],
			mv_field_names => $results[1],
			mv_field_hash => $results[2],
		},
		body => $body
	});
}
EOR
