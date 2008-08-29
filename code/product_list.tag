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

=item ml

How many matches to display on one page

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
	my $ml = $opt->{ml} || $opt->{mv_matchlimit} || 0;
	my $more = $opt->{more} || 1;
	my $form = $opt->{form};
	if ($category){
		$category = " AND pc.category='$category' ";
	}

	$Tag->perl( {tables => 'products product_categories'} );
	my $sql = qq{
		SELECT p.sku,p.manufacturer,p.name,p.description,p.price
		FROM products p LEFT OUTER JOIN product_categories pc
		ON p.sku=pc.sku WHERE p.inactive IS NOT TRUE $category
		};

	return $Tag->query({
		prefix => $prefix,
		more_routine => 'paging',
		form => $form,
		ml => $ml,
		more => $more,
		sql => $sql,
		list => 1,
		body => $body
	});
}
EOR
