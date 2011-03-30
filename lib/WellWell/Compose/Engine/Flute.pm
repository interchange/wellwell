# WellWell::Compose::Engine::Flute - Flute composing engine for WellWell
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

package WellWell::Compose::Engine::Flute;

use strict;
use warnings;

use WellWell::Compose::Component::Flute;

sub new {
	my $class = shift;
	my $self = {@_};

	$self->{database} = new Template::Flute::Database::Rose(dbh => $self->{dbh});
	
	bless $self;
	return $self;
}	

sub locate_component {
	my ($self, $name) = @_;
	my (%component_hash, $component, $component_dir);

	$component_dir = "$::Variable->{MV_COMPONENT_DIR}";

	if (-d "$component_dir/$name") {
		# separate directory for component
		$component_dir = "$component_dir/$name";
	}

	if (-f "$component_dir/$name.xml"
		&& -f "$component_dir/$name.html") {
		%component_hash = (database => $self->{database},
						   name => $name,
						   specification => "$component_dir/$name.xml",
						   template => "$component_dir/$name.html");
		
		$component = new WellWell::Compose::Component::Flute(%component_hash);
		return $component;
	}
	
	return '';
}

1;
