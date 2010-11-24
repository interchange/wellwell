# WellWell::Iterate - WellWell iterating routines
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

package WellWell::Iterate;

use strict;
use warnings;

use Vend::Config;
use Vend::Data;

use WellWell::Engine qw/load_engine/;

Vend::Config::parse_tag('UserTag', 'iterate AddAttr');
Vend::Config::parse_tag('UserTag', 'iterate HasEndTag');
Vend::Config::parse_tag('UserTag', 'iterate MapRoutine WellWell::Iterate::iterate');

sub iterate {
	my ($opt, $body) = @_;
	my ($engine, $iter, $record, @out);

	if (exists $opt->{query}) {
		if (ref($opt->{query}) eq 'HASH') {
			# use query builder
			$engine = load_zoom();
			$iter = $engine->{database}->build($opt->{query});
		}
	}

	unless ($iter) {
		die "Iterator not found\n";
	}

	while ($record = $iter->next()) {
		# turn hash into array
		my @keys = keys(%$record);
		my @vals;

		for (@keys) {
			push(@vals, $record->{$_});
		}
		
		push (@out, Vend::Tags->loop({prefix => 'item', body => $body,
									  object => {mv_results => [\@vals],
												 mv_field_names => \@keys}}));
	}

	return join('', @out);
}

sub load_zoom {
	my ($engine);

	if ($Vend::Session->{engine}->{zoomx}) {
		# reuse existing zoom engine
		$engine = $Vend::Session->{engine}->{zoom};
	}
	else {
		# load zoom engine
		$engine = load_engine('zoom', database_exists_ref('products')->dbh());
		$Vend::Session->{engine}->{zoom} = $engine;
	}

	return $engine;
}
