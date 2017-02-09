# WellWell::Compose::Component::Flute - Flute component class for WellWell
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

package WellWell::Compose::Component::Flute;

use strict;
use warnings;

use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;

use WellWell::Filter::Link;

sub new {
	my ($class, @parms) = @_;

	my $self = {@parms};

	bless $self;

	return $self;
}

sub process {
	my ($self, $attributes) = @_;
	my ($content, $spec, $flute);
	my (%filters, $subname, $subref);

	# filters
	$filters{link} = \&WellWell::Filter::Link::filter;

    my %args = ( template_file => $self->{template},
                 filters => \%filters,
                 values => $attributes,
                 iterators => {
                     cart => $Vend::Items,
                 }
             );

	$flute = Template::Flute->new(%args);

	# call component load subroutine
	$subname = "component_$self->{name}_load";
	$subref = $Vend::Cfg->{Sub}{$subname} || $Global::GlobalSub->{$subname};

	if ($subref) {
		$subref->($self->{name}, $flute->specification, $flute->template, $flute);
	}

	return $flute->process($attributes);
}

1;
