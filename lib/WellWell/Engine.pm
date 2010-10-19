# WellWell::Engine - WellWell template engine routines
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

package WellWell::Engine;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/load_engine/;

our %engines = ('itl' => 'WellWell::Compose::Engine::ITL',
				'zoom' => 'WellWell::Compose::Engine::Zoom');

use Vend::Config;

sub load_engine {
	my ($name, $dbh) = @_;
	my ($class, $object);
	
	# lookup class for engine
	if (exists $engines{$name}) {
		$class = $engines{$name};

		eval "require $class";
		if ($@) {
			die "Failed to load $class: $@\n";
		}

		eval {
			$object = $class->new(dbh => $dbh);
		};
		if ($@) {
			die "Failed to load engine $name: $@\n";
		}
		
		return $object;
	}

	return;
}

1;
