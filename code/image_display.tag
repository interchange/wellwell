UserTag image_display Order sku group
UserTag image_display HasEndTag
UserTag image_display Routine <<EOR
sub {
	my ($sku, $group, $body) = @_;
	my ($sku_qtd, $group_qtd, $set, $img, $loc, $hash);

	$Tag->perl({tables => 'images product_images'});

	$sku_qtd = $Db{product_images}->quote($sku);
	$group_qtd = $Db{product_images}->quote($group);

	$set = $Db{product_images}->query({sql => qq{select location,width,height from images I, product_images PI where PI.sku = $sku_qtd and PI.image_group = $group_qtd and PI.image = I.code}, hashref => 1});

	if (@$set) {
		if (@$set > 1) {
			Log("More than one image found for sku $sku and group $group.");
		}
		
		$hash = $set->[0];
	} else {
#		Log("No image found for sku $sku and group $group.");
	}

	if ($body) {
		return $Tag->uc_attr_list({hash => $hash, body => $body});
	} 
	elsif ($hash) {
		return $hash->{location};
	}

	# dummy image
	return "nopic-$group.jpg";
}
EOR
