# WellWell::Core - WellWell core routines
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

package WellWell::Core;

use Vend::Config;

use WellWell::Cart;

# setup configuration directives
Vend::Config::parse_directive('Hook', 'Hook hook');

sub plugins {
	my @plugins;
	
	# simply return a list of plugins sitting in $Variable
	@plugins = split(/,/, $::Variable->{PLUGINS});

	return @plugins;
}

sub hooks {
	my ($function, $name, @args) = @_;

	if ($function eq 'run') {
		if (exists $Vend::Cfg->{Hook}->{$name}) {
			my @hooks = @{$Vend::Cfg->{Hook}->{$name}};

			for my $hook (@hooks) {
				$hook->(@args);
			}
		}
	}
}

package Vend::Config;

sub parse_hook {
	my ($item, $settings) = @_;

	# parse routine is called once per catalog, regardless of configuration
	# directives
	return {} unless $settings;

	my ($name, $param, $value) = split(/\s+/, $settings);

	if (exists $C->{Sub}->{$param}) {
		push(@{$C->{$item}->{$name}}, $C->{Sub}->{$param});
	}
	else {
		config_error('Subroutine %s missing.', $param);
	}
	
	return $C->{$item};
}

1;
