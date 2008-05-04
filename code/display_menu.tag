UserTag display_menu Order name root element_prefix element_suffix level_prefix level_suffix
UserTag display_menu Routine <<EOR
sub {
	my ($name, $root, $element_prefix, $element_suffix, $level_prefix, $level_suffix) = @_;
	my $output;

	$element_prefix = $element_prefix || '<li>';
	$element_suffix = $element_suffix || '</li>';
	$level_prefix = $level_prefix || '<ul>';
	$level_suffix = $level_suffix || '</ul>';
	$root = $root || 0;

	$Tag->perl( {tables => 'menus'} );
	my $db = $Db{menus};
	$name = $db->quote($name, 'menu_name');

	display_children($root, 0);

	sub display_children {	
		my ($parent, $level) = @_;
		$output .= "$level_prefix\n";

		my $sql = "SELECT code,name,url FROM menus WHERE menu_name = $name AND parent = $parent";
		my $set = $db->query({sql => $sql, hashref => 1});

		foreach my $row (@$set){
			$output .= "$element_prefix $row->{name} $element_suffix\n";
			display_children($row->{code}, $level + 1);
		}

		$output .= "$level_suffix\n";
	}
	
return $output;
}
EOR
