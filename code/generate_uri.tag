UserTag generate_uri Order table
UserTag generate_uri Documentation <<EOD

=head1 NAME

generate-uri - Generates a pretty URL for a hierarchical structure and stores it in the database

=head1 SYNOPSIS

[generate-uri table]

=head1 DESCRIPTION

Generates an URL for hierarchical structures such as categories and menus. Uses parent field in the table to get the parents to the root item and generates a pretty url (parents_parent/parent/child). This url is stored in the same table (usually in the URL field). 

This tag is normally used in an Interchange job, which fills the entire table, or as a part of administration interface (where you run it when you add or edit a category, for example).

The URL is retrieved by using an ActionMap or a similar approach to display the page.

The active settings are:

=over 4

=item table

Table containing the hierarchical structure

=item key_field

Name of the field having the key element. Defaults to 'code'

=item display_field

Field from which the pretty URL is generated from. Defaults to 'name'

=item parent_field

Name of the field having the parent key. Defaults to 'parent'

=item uri_field

Name of the field where the URI will be stored to

=item nonword_fill

What should be used to fill nonword characters in URI (whitespaces,...). Defaults to underscore.

=item dir_divider

How to divide elements. Defaults to slash ('/').

=back

=head1 EXAMPLES

[generate_uri categories]

[generate_uri table='articles' display_field='title' key_field='article_id' parent_field='parent_article']

=head2 

=back

=head1 AUTHORS

Jure Kodzoman <jure@tenalt.com>

Stefan Hornburg <racke@linuxia.de>

=cut

EOD
UserTag generate_uri Routine <<EOR
sub {
	my ($table, $opt) = @_;
	my ($db, @parents, $level, $name, $uri);
	my $key_field = $opt->{'key_field'} || 'code';
	my $display_field = $opt->{'display_field'} || 'name';
	my $parent_field = $opt->{'parent_field'} || 'parent';
	my $uri_field = $opt->{'uri_field'} || 'uri';
	my $nonword_fill = $opt->{'nonword_fill'} || '_';
	my $dir_divider = $opt->{'dir_divider'} || '/';

	$Tag->perl({tables => $table});
	$db = $Db{$table};

	my $sql = qq{SELECT $key_field,$display_field,$parent_field FROM $table};
	my $rows = $db->query({sql => $sql, hashref => 1});

	foreach my $row (@$rows){
		$level = 0;
		@parents = ();

		# Recursive method to get all parents of the element.
		$sub = sub {
			my ($level, $code) = @_;	
			return 1 unless $code;
	
			my $sql = qq{
				SELECT $key_field, $display_field, $parent_field 
				FROM $table 
				WHERE $key_field = '$code'
			};

			my $rows = $db->query({sql => $sql, hashref => 1});
			my $row = $$rows[0];
	
			my $name = $row->{$display_field};
			$name =~ s/\W+/$nonword_fill/g;
			$name =~ tr/[A-Z]/[a-z]/;

			unshift(@parents, $name);

			$sub->($level+1, $row->{$parent_field});
		};

		&$sub ($level, $row->{$key_field});
		$uri = join( $dir_divider, @parents );

		# Insert the URI into database
		my %columns = ( uri => $uri );
		$db->set_slice($row->{$key_field}, \%columns);
	}
	return 1;
}
EOR
