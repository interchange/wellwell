UserTag product_order Order sku qty
UserTag product_order AddAttr
UserTag product_order Routine <<EOR
sub {
	my ($sku, $qty, $opt) = @_;
	my ($class, $qty_el, $qty_class, $text, $form, $sid, $action);

	$class = $opt->{class} || 'cart';

	if ($qty) {
		$qty_class = $opt->{qty_class} || 'cart';
		$qty_el = qq{<input name="mv_order_quantity" class="$qty_class" value="$qty" size="2">};
	}
	else {
		$qty_el = '';
	}

	$text = $opt->{text} || errmsg('Add to Cart');

	# produce form to order item
	$sid = $Tag->form_session_id();
	$action = $Tag->area({href => $Config->{Special}->{order}, match_security => 1});

	$form = <<EOF;
<form action="$action" method="post">
$sid
<input type="hidden" name="mv_action" value="refresh">
<input type="hidden" name="mv_order_item" value="$sku">
$qty_el
<button class="$class" type="submit"><span>$text</span></button>
</form>
EOF

	return $form;
}
EOR
