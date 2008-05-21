UserTag image_batch_resize Order code
UserTag image_batch_resize Documentation <<EOD

=head1 NAME

image_batch_resize - Resize images according to list from database, and store them in predefined location

=head1 SYNOPSIS

[image_batch_resize 1]

=head1 DESCRIPTION

This Tag heavily depends on wellwell infrastructure. It will take image code from images table as an argument and resize that image to each of the sizes defined in image_sizes. Images are stored in IMAGE_DIR/$image_code directory, where $image_code represents the actual code of the image, and IMAGE_DIR is a variable holding the images path inside catalog.

The active settings are:

=over 4

=item code

Code of the image you wish to resize. Mandatory field.

=back

=head1 EXAMPLES

For easier understanding, let's assume some settings. You can easily tune these to your own fitting:

In our example image format in database (column format in images table) is jpg. IMAGE_DIR is set to static/images as in default installation. Image_sizes table holds sizes big, small and medium.

[image_batch_resize 1] - Resizes image with code 1 to the sizes from image_sizes

Calling this tag would produce the following results:

It would take the static/images/1/original.jpg file, and convert it to big.jpg, small.jpg and medium.jpg. The resulting files would be stored in the same directory as original.jpg

=back

=head1 AUTHORS

Jure Kodzoman <jure@tenalt.com>

Stefan Hornburg <racke@linuxia.de>


=cut

EOD
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
