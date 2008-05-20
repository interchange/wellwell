UserTag image_batch_resize Order code
UserTag image_batch_resize Routine <<EOR
sub {
	my ($code) = @_;
	my ($db, $imgref, $format, $dir, $original);

	$Tag->perl({tables => 'images image_sizes'});

	$db = $Db{images};

	unless ($imgref = $db->row_hash($code)) {
		Log("Image with code $code missing in images table.");
		return 0;
	}

	$format = $imgref->{format};
	$dir =  "$Variable->{IMAGE_DIR}/$code";
	$original = "$dir/original.$format";

	# Get all possible image sizes
	my ($sql, $sizes);

	$sql = qq{SELECT * FROM image_sizes};
	$sizes = $db->query({sql => $sql, hashref => 1});

	foreach my $size (@$sizes){
		my $destination = "$dir/$size->{'name'}.$format";
		$Tag->image_resize({
			name => $original,
			outfile => $destination,
			width => $size->{'width'},
			height => $size->{'height'}
		});
	}

	return 1;
}
EOR
