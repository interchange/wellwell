UserTag image_update Order filename label code
UserTag image_update AddAttr
UserTag image_update Routine <<EOR
sub {
	my ($filename, $label, $code, $opt) = @_;
	my ($inforef, $imgfilename, $origfilename, $imgprefix, $imgname, $imgdir, 
		$imgcode, $sizes, $location,$destination, $ret, $filetime, $set, 
		$exists);

	$imgprefix = $opt->{image_dir_prefix} || $Variable->{IMAGE_DIR_PREFIX};
	$imgdir = $opt->{image_dir} || $Variable->{IMAGE_DIR} || 'images';

	# ensure that file exists
	unless (-f $filename) {
		Log("Missing image file %s", $filename);
		return;
	}

	# determine age of image
	unless ($filetime = $Tag->file_info({name => $filename, time => 1})) {
		Log("Failed to determine time for %s", $filename);
		return;
	}

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
	if ($imgprefix) {
		$imgfilename = "$imgprefix/$imgdir/$imgname.$inforef->{type}";
	}
	else {
		$imgfilename = "$imgdir/$imgname.$inforef->{type}";
	}

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
		# existing image has been updated
		$imgcode = $Db{images}->set_slice([{dml => 'update'}, $imgcode], \%image);

		unless ($imgcode) {
			Log("Failed to update database record for %s", $filename);
			return;
		}
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

	# get current entries in product_images
	my %prod_images;

	$set = $Db{product_images}->query(q{select code,image_group from product_images where sku = '%s'}, $code);
	for (@$set) {
		$prod_images{$_->[1]} = $_->[0];
	}
	
	# resize image
	for my $size (@$sizes) {
		$location = "$imgdir/$size->{name}/$imgname.$inforef->{type}";
		if ($imgprefix) {
			$destination = "$imgprefix/$location";
		}
		else {
			$destination = $location;
		}

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
		if (exists $prod_images{$size->{name}}) {
			$ret = $Db{product_images}->set_slice([{dml => 'update'}, $prod_images{$size->{name}}],
									   image => $imgcode,
									   image_group => $size->{name},
									   location => $location);
			delete $prod_images{$size->{name}};
		}
		else {
			$ret = $Db{product_images}->set_slice([{dml => 'insert'}, ''], sku => $code,
									   image => $imgcode,
									   image_group => $size->{name},
									   location => $location);
		}
	}

	# remove product images which aren't in use anymore
	for (keys %prod_images) {
		$Db{product_images}->delete_record($prod_images{$_});
	}

	return 1;
}
EOR
