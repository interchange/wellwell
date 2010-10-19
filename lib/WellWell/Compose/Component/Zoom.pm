# WellWell::Compose::Component::Zoom - Zoom component class for WellWell
#
# Copyright (C) 2010 Stefan Hornburg (Racke) <racke@linuxia.de>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

package WellWell::Compose::Component::Zoom;

use Template::Zoom;
use Template::Zoom::Specification::XML;
use Template::Zoom::HTML;

sub new {
	my ($class, @parms) = @_;

	my $self = {@parms};

	bless $self;

	return $self;
}

sub process {
	my ($self, $attributes) = @_;
	my ($content, $xml_spec, $spec, $html_object, $zoom);

	# parse specification
	$xml_spec = new Template::Zoom::Specification::XML;

	unless ($spec = $xml_spec->parse_file($self->{specification})) {
		die "$0: error parsing $xml_file: " . $xml_spec->error() . "\n";
	}

	$html_object = new Template::Zoom::HTML;

	$html_object->parse_template($self->{template}, $spec);

	for my $list_object ($html_object->lists()) {
		# seed and check input
		$list_object->input(\%input);
	}

	$zoom = new Template::Zoom ($html_object, $self->{dbh});

	return $zoom->process($attributes);

}
			
1;
