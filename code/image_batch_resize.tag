UserTag image_batch_resize Order code
UserTag image_batch_resize Routine <<EOR
sub {
	my ($code) = @_;

	$Tag->perl( {tables => 'images image_sizes'} );
	my $db = $Db{images};

	my $sql = qq{ SELECT code,format FROM images where code = '$code' };
	my $images = $db->query({sql => $sql, hashref => 1});
	my $format = $images->[0]->{'format'};

	# Check if this image exists in database
	if (!$format){
		::logError("Image with code $code cannot be found in the images table.");
		return 0;
	}

	my $dir =  "$Variable->{IMAGE_DIR}/$code";
	my $original = "$dir/original.$format";

	# Get all possible image sizes
	$sql = qq{ SELECT * FROM image_sizes};
	my $sizes = $db->query({sql => $sql, hashref => 1});

	foreach my $size (@$sizes){
		my $destination = "$dir/$size->{'name'}.$format";
		$Tag->image_resize({
			name => $original, 
			outfile => $destination, 
			width => $size->{'width'}, 
			height => $size->{'height'}
			});
		}	
}
EOR
