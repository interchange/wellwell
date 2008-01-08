#	generate_rand.tag - Random String Generation tag
#	---------------------
#
#	Copyright (c) 2002-2003 Cursor Software Limited.
#	Copyright (c) 2007 Tenalt d.o.o.
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public
#	License along with this program; if not, write to the Free
#	Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
#	MA  02111-1307  USA.
#

UserTag generate_rand Documentation <<EOD

=head1 NAME

generate_rand - Random string generation

=head1 SYNOPSIS

[generate-rand]

=head1 DESCRIPTION

Generate a specified-length string filled with random characters.
The result could be used as a random key.

The active settings are:

=over 4

=item length

Length of produced string. Defaults to 1.

=item type

Type of string to be produced. Can be alpha, alphanumeric or number.

=back

=head1 EXAMPLES


[generate-rand length="4"] - Displays something like "5624"

[generate-rand length="6" type=alpha] - Displays something like "arcgdg"

=back

=head1 AUTHORS

Kevin Walsh <kevin@cursor.biz>

Jure Kodzoman <jure@tenalt.com>


=cut

EOD


UserTag generate_rand Order length type
UserTag generate_rand Routine <<EOR
sub {
	my ($length, $type) = @_;
	my $out;
	my @chars;

	# defaults
	$type ||= 'number';
	$length ||= 1;

	if ($type eq 'number'){
		@chars = ('0'..'9');
	}
	elsif ($type eq 'alpha'){
		@chars = ('a'..'z','A'..'Z');
	}
	elsif ($type eq 'alphanumeric'){
		@chars = ('a'..'z','A'..'Z','0'..'9');
	}else{
		::logError("Invalid type '$type' called in generate_rand.tag");
	}

	$out .= $chars[rand scalar(@chars)] for (1 .. $length);
	$out;
}
EOR
