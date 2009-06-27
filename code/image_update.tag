UserTag image_update Order filename label code
UserTag image_update AddAttr
UserTag image_update Routine <<EOR
sub {
	my ($filename, $label, $code) = @_;
	my ($inforef, $imgfilename, $origfilename, $imgname, $imgdir, $imgcode, 
		$sizes, $destination, $ret, $filetime, $set, $exists);

	$imgdir = $Variable->{IMAGE_DIR} || 'images';

	# ensure that file exists
	unless (-f $filename) {
		Log("Missing image file %s", $filename);
		return;
	}

	# determine age of image
	$filetime = $Tag->file_info({name => $filename, time => 1});

	$Tag->perl({tables => 'images image_sizes product_images'});
	
	# image already present ?
	$set = $Db{images}->query(q{select code,original_time,name from images where original_file = '%s'}, $filename);
	if (@$set) {
		if ($set->[0]->[1] == $filetime) {
			# no changes
			return;
		}
		$imgcode = $set->[0]->[0];
		$origfilename = $set->[0]->[2];
		$exists = 1;
	}

	# get dimensions for original file
	unless ($inforef = $Tag->image_info({name => $filename, hash => 1})) {
		Log("Error getting info on %s.");
		return;
	}

	# determine file name for the image
	$imgname = $Tag->clean_url($label, $code);
	$imgfilename = "$imgdir/$imgname.$inforef->{type}";

	# copy file to new location
	unless ($Tag->cp({from => $filename, 
				  to => $imgfilename,
				  umask => 22})) {
		Log("Error copying %s to %s", $filename, $imgfilename);
		return;
	}

	if ($imgcode && $origfilename ne $imgfilename) {
		$ret = $Tag->unlink_file($origfilename);
		Log("Deleted file $origfilename: $ret.");	
	}

	# record for original image
	my %image = (name => $imgfilename,
		 created => $filetime,
		 width => $inforef->{width},
		 original_file => $filename,
	 	 original_time => $filetime,
	 	 height => $inforef->{height},
	 	 format => $inforef->{type});

	if ($imgcode) {
	}  else {	
	

		$imgcode = $Db{images}->set_slice([{dml => 'insert'}], \%image);

		unless ($imgcode) {
			Log("Failed to create database record for %s", $filename);
			return;
		}
	}

	# determine sizes
	$sizes = $Db{image_sizes}->query({sql => q{select * from image_sizes},
		hashref => 1});

	# resize image
	for my $size (@$sizes) {
		$destination = "$imgdir/$size->{name}/$imgname.$inforef->{type}";

		$ret = $Tag->image_resize({
			name => $imgfilename,
			outfile => $destination,
			width => $size->{width},
			height => $size->{height}
		});

		unless ($ret) {
			Log ("Error on resizing image to %s", $destination);
			return;
		}

		# store in database
		$ret = $Db{product_images}->set_slice('', sku => $code,
									   image => $imgcode,
									   image_group => $size->{name},
									   location => $destination);
	}

	return 1;
}
EOR
