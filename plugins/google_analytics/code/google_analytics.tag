UserTag google_analytics Order function code
UserTag google_analytics Routine <<EOR
sub {
	my ($function, $code) = @_;
	my (@trans, $set, $out);
	
	return unless $function eq 'transaction';

	$Tag->perl({tables => 'transactions orderline'});
	
	# transaction details
	@trans = $Db{transactions}->get_slice($code, [qw/affiliate total_cost salestax shipping city state country/]);
	unshift(@trans, $code);

	$out = q{pageTracker._addTrans(
} . join(",\n", map {$Tag->jsqn("$_")} @trans)
. ");\n\n";

	# orderline entries
	$set = $Db{orderline}->query({sql => qq{select order_number,sku,description,'',price,quantity from orderline where order_number = $code}});
	for (@$set) {
		$out .= q{pageTracker._addItem(
} . join(",\n", map {$Tag->jsqn($_)} @$_)
. ");\n\n";
}

	# complete transaction tracking
	$out .= q{pageTracker._trackTrans();
};

	return $out;
}
EOR

