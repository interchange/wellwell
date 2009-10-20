# WellWell::Menu - WellWell Menu Functions/Tags
#
# Copyright (C) 2009 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package WellWell::Menu;

use strict;
use warnings;

use Vend::Config;
use Vend::Tags;
use Vend::Data;

Vend::Config::parse_tag('UserTag', 'menu_display Order name');
Vend::Config::parse_tag('UserTag', 'menu_display AddAttr');
Vend::Config::parse_tag('UserTag', 'menu_display MapRoutine WellWell::Menu::display');

sub display {
	my ($name, $opt) = @_;
	my ($set, @entries, $name_qtd, @fields, $fstr, $base_url, $selected);
	my ($db_menus);
	
	$db_menus = database_exists_ref('menus');
	
	$name_qtd = $db_menus->quote($name);

	@fields = qw/code name url parent permission/;
		
	$fstr = join(',', @fields);

	$set = $db_menus->query({sql => qq{select $fstr from menus where menu_name = $name_qtd order by parent asc, weight desc, code}, hashref => 1});

	for (@$set) {
		next unless Vend::Tags->acl('check', $_->{permission});

		push(@entries, $_);
	}

	if ($opt->{hooks}) {
		my @hook_entries = Vend::Tags->call_hooks('menu', 'collect', $name, $opt);

		for (@hook_entries) {
			next unless ref($_) eq 'HASH';
			push(@entries, $_);
		}
	}
	
	return build_entries(\@entries, $opt);
}

sub build_entries {
	my ($entries_ref, $opt) = @_;
	my (@out, $ref, $base_url, $uri, $selected);

	if ($opt->{selected}) {
		$base_url = $Vend::Session->{last_url};
		$base_url =~ s%^/%%;
	}
	for (my $i = 0; $i < @$entries_ref; $i++) {
		$ref = $entries_ref->[$i];

		if ($ref->{url}) {
			if ($opt->{selected}) {
				if (index($base_url, $ref->{url}) == 0) {
					$selected = qq{ class="$opt->{selected}"};
				}
				else {
					$selected = '';
				}
			}
	
			$uri = Vend::Tags->area($ref->{url});
			$out[$i] = qq{<li$selected><a href="$uri">$ref->{name}</a></li>};
		}
		else {
			$out[$i] = qq{<li>$ref->{name}</li>};
		}
	}

	return q{<ul>} . join('', @out) . q{</ul>};
}

1;
