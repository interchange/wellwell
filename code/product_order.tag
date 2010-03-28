UserTag product_order Order sku qty
UserTag product_order AddAttr
UserTag product_order Routine <<EOR
sub {
	my ($sku, $qty, $opt) = @_;
	my ($class, $qty_el, $qty_class, $text, $form, $sid, $action, $button, $type, $separate_items, $separate_el);

	$class = $opt->{class} || 'cart';

	$type = $opt->{type} || 'button';

	$separate_items = $opt->{separate_items} || 0;

	if ($qty) {
		$qty_class = $opt->{qty_class} || 'cart';
		$qty_el = qq{<input name="mv_order_quantity" class="$qty_class" value="$qty" size="2" />};
	}
	else {
		$qty_el = '';
	}

	$text = $opt->{text} || errmsg('Add to Cart');

	# produce form to order item
	$sid = $Tag->form_session_id();
	$action = $Tag->area({href => $Config->{Special}->{order}, match_security => 1});

	$button = $type eq 'button'
			?
			qq{<button class="$class" type="submit"><span>$text</span></button>}
			:
			qq{<input type="submit" class="$class" value="$text" />};

	$separate_el = qq{<input type="hidden" name="mv_separate_items" value="$separate_items" />} if defined $opt->{separate_items};

	$form = <<EOF;
<form action="$action" method="post">
$sid
<input type="hidden" name="mv_action" value="refresh" />
<input type="hidden" name="mv_order_item" value="$sku" />
$separate_el
$qty_el
$button
</form>
EOF

	return $form;
}
EOR
