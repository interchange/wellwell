# WellWell::Settings - WellWell settings from database
#
# Copyright (C) 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package WellWell::Settings;

use strict;
use warnings;

use Vend::Config;
use Vend::Data;

Vend::Config::parse_tag('UserTag', 'settings Order name');
Vend::Config::parse_tag('UserTag', 'settings AddAttr');
Vend::Config::parse_tag('UserTag', 'settings MapRoutine WellWell::Settings::settings');

sub settings {
	my ($name, $opt) = @_;
	my ($sql, $fields, @conds, $cond_str, $db_settings, $set, $value, %ret, $multi);
	
	unless ($db_settings = database_exists_ref('settings')) {
		die errmsg("Database missing in [settings] tag: %s", 'settings');
	}
	
	# build query
	if ($name) {
		if (ref($name) eq 'ARRAY') {
			# list of settings
			$cond_str = join(',', map {$db_settings->quote($_)} @$name);
			push (@conds, "name in ($cond_str)");
			$fields = 'name,value';
			$multi = 1;
		}
		else {
			push (@conds, 'name = ' . $db_settings->quote($name));
			$fields = 'value';
		}
	}
	else {
		$fields = 'name,value';
		$multi = 1;
	}

	if ($opt->{site}) {
		push (@conds, 'site = ' . $db_settings->quote($opt->{site}));
	}
	if ($opt->{scope}) {
		push (@conds, 'scope = ' . $db_settings->quote($opt->{scope}));
	}
	
	if (@conds) {
		$cond_str = ' where ' . join(' and ', @conds);
	}
	else {
		$cond_str = '';
	}
	
	$set = $db_settings->query(qq{select $fields from settings$cond_str});

	if ($multi) {
		# return hashref for name/value pairs
		for (@$set) {
			$ret{$_->[0]} = $_->[1];
			if ($opt->{set}) {
				if ($opt->{scope}) {
					$::Variable->{uc($opt->{scope} . '_' . $_->[0])} = $_->[1];
				}
				else {
					$::Variable->{uc($_->[0])} = $_->[1];
				}
			}
		}
		
		return \%ret;
	}

	if (@$set == 1) {
		$value = $set->[0]->[0];

		if ($opt->{set}) {
			$::Variable->{uc($name)} = $value;
		}
	}
	else {
		# fallback to default value
		$value = $::Variable->{uc($name)};
	}
	
	return $value;
}

1;
