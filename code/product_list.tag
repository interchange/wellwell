UserTag product_list Order category
UserTag product_list HasEndTag 
UserTag product_list AddAttr 
UserTag product_list Documentation <<EOD

=head1 NAME

product_list - Displays a list of products

=head1 SYNOPSIS

[product-list category] ... [/product-list]

=head1 DESCRIPTION

Returns a list of products from the database.

The active settings are:

=over 4

=item category

Display only products from this category.

=item prefix

List prefix.

=back

=head1 EXAMPLES

[product-list category=1]
[list]
<h3>[product-field manufacturer] [product-field name]</h3>
<p class="description"> [product-description] </p>
<p class="price"> [product-price] </p>
[/list]
[no-match]
[L]No products found in this category.[/L]
[/no-match]
[/product-list]

=back

=head1 AUTHORS

Jure Kodzoman <jure@tenalt.com>

Stefan Hornburg <racke@linuxia.de>


=cut

EOD
UserTag product_list Routine <<EOR
sub {
	my ($category, $opt, $body) = @_;
	my $output;
	my $prefix = $opt->{prefix} || 'product';

	if ($category){
		$category = " AND pc.category='$category' ";
	}

	$Tag->perl( {tables => 'products product_categories'} );
	my $db = $Db{products};

	my $sql = qq{
		SELECT p.sku,p.manufacturer,p.name,p.description,p.price
		FROM products p LEFT OUTER JOIN product_categories pc
		ON p.sku=pc.sku WHERE p.inactive IS NOT TRUE $category
		};
	my @results = $db->query({sql => $sql});

	return $Tag->loop({
		prefix => $prefix,
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
