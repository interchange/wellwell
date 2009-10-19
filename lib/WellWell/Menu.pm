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
	my ($set, $uri, @entries, $name_qtd, @fields, $fstr, $base_url, $selected);
	my ($db_menus);
	
	$db_menus = database_exists_ref('menus');
	
	$name_qtd = $db_menus->quote($name);

	@fields = qw/code name url parent permission/;
		
	$fstr = join(',', @fields);

	$set = $db_menus->query({sql => qq{select $fstr from menus where menu_name = $name_qtd order by parent asc, weight desc, code}, hashref => 1});
	
	if ($opt->{selected}) {
		$base_url = $Vend::Session->{last_url};
		$base_url =~ s%^/%%;
	}

	for (@$set) {
		next unless Vend::Tags->acl('check', $_->{permission});

		if ($opt->{selected}) {
			if (index($base_url, $_->{url}) == 0) {
				$selected = qq{ class="$opt->{selected}"};
			}
			else {
				$selected = '';
			}
		}

		$uri = Vend::Tags->area($_->{url});

		push(@entries, qq{<li$selected><a href="$uri">$_->{name}</a></li>});
	}

	if ($opt->{hooks}) {
		my @hook_entries = Vend::Tags->call_hooks('menu', 'collect', $name, $opt);

		for (@hook_entries) {
			next unless ref($_) eq 'HASH';
			if ($_->{url}) {
				$uri = Vend::Tags->area($_->{url});
				push(@entries, qq{<li><a href="$uri">$_->{name}</a></li>});
			}
			else {
				push(@entries, qq{<li>$_->{name}</li>});
			}
		}
	}

	return q{<ul>} . join('', @entries) . q{</ul>};
}

1;
