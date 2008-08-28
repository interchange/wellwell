# 
# This tag is used for display of images. It heavily depends
# on wellwell database and directory structure. Tag shows thumbnails or original
# sized images for entity that you wish to display them for. Joining tables are used
# to connect entities to images.
#
# image-list returns a [list], with all fields from database tables used and an additional field named [image-list-param img-src] which returns <img-src ...> of the image using wellwell structure.
#
#
# where        - Limit a query with sql where clause (without where keyword). 
#                'i' is the name of the images table and 'ji' is the name of 
#                the join_table for use inside the where clause 
#                Example: where='i.active IS TRUE AND ji.article_gallery IS FALSE'
#
# key_field    - field used for key inside join table (ie. sku in product_images)
#
# key          - value of key_field by which to search (ie. value of the sku
#               of which for which you wish to display images
#
# join_table   - name of the joining table, (ie. product_images, article_images). 
#                Usually this table contains key of the entity and 
#                code of the image. Can contain additional fields.
#
# size         - Name of the image size. An entry has to exist in image_sizes table.
#
#
UserTag image_list Order where key key_field join_table size ml
UserTag image_list AddAttr
UserTag image_list HasEndTag 
UserTag image_list Routine <<EOR
sub {
	my ($where, $key, $key_field, $join_table, $size, $matchlimit, $body) = @_;

	if($where){
		$where = " AND $where ";
	}

	if($key && $key_field) {
		$key = "AND ji.$key_field = '$key' ";
	}

	$Tag->perl( {tables => 'images product_images'} );
	my $db = $Db{products};

	my $sql = qq{
		SELECT *
		FROM images i 
		LEFT OUTER JOIN $join_table ji 
		ON i.code=ji.image WHERE i.inactive is false $key $where
		};

	my (@field_names, %field_hash);
	my $results = $db->query({sql => $sql, hashref => 1});

	if (@$results) {
		@field_names = keys(%{$results->[0]});
		for (my $i = 0; $i < @field_names; $i++) {
			$field_hash{$field_names[$i]} = $i;
		}

		foreach my $result (@$results){
			$result->{'img-src'} = qq{<img src="$Variable->{IMAGE_URL}/$result->{'image'}/$size.$result->{'format'}">};
		}
	}

	return $Tag->loop({
		prefix => 'image-list',
		ml => $matchlimit,
		object => 
		{
			mv_results => $results,
			mv_field_names => \@field_names,
			mv_field_hash => \%field_hash,
		},
		body => $body
	});
}
EOR

