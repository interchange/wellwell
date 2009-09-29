UserTag product_display Order sku format
UserTag product_display HasEndTag
UserTag product_display Routine <<EOR
sub {
	my ($sku, $format, $body) = @_;
	my ($main, @content, $disp);

	# determine main content
	$main = $Tag->fly_list({code => $sku, body => $body});

	# let plugins add their own content
	@content = $Tag->call_hooks({name => 'node_view', 
		mode => 'collect',
		type => 'products',
		code => $sku});

	if (@content) {
		return $main . join('', @content);
	}

	return $main;
}
EOR
