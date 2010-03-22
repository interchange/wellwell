# Vend::UUID - Interchange UUID helper functions
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

package Vend::UUID;

use strict;
use warnings;

use Data::UUID;

use Vend::Config;

Vend::Config::parse_tag('UserTag', 'uuid Order format namespace name');
Vend::Config::parse_tag('UserTag', 'uuid MapRoutine Vend::UUID::uuid');

sub uuid {
	my ($format, $namespace, $name) = @_;
	my ($uuid, $ret);

	$uuid = new Data::UUID;
	
	if ($format eq 'binary') {
		if ($namespace =~ /\S/) {
			$ret = $uuid->create_from_name_bin($namespace, $name);
		}
		else {
			$ret = $uuid->create_bin();
		}
	}
	elsif ($format eq 'hex') {
		if ($namespace =~ /\S/) {
			$ret = $uuid->create_from_name_hex($namespace, $name);
		}
		else {
			$ret = $uuid->create_hex();
		}
	}
	elsif ($format eq 'base64') {
		if ($namespace =~ /\S/) {
			$ret = $uuid->create_from_name_b64($namespace, $name);
		}
		else {
			$ret = $uuid->create_b64();
		}
	}
	else {
		# conventional UUID string format used as default format
		if ($namespace =~ /\S/) {
			$ret = $uuid->create_from_name_str($namespace, $name);
		}
		else {
			$ret = $uuid->create_str();
		}
	}
	
	return $ret;
}

return 1;
