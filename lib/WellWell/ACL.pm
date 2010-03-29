# WellWell::ACL - WellWell access control routines
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

package WellWell::ACL;

use strict;
use warnings;

use Vend::Config;
use Vend::Data;

Vend::Config::parse_tag('UserTag', 'acl Order function permission uid');
Vend::Config::parse_tag('UserTag', 'acl AddAttr');
Vend::Config::parse_tag('UserTag', 'acl HasEndTag');
Vend::Config::parse_tag('UserTag', 'acl MapRoutine WellWell::ACL::acl');

sub acl {
	my ($function, $permission, $uid, $opt, $body) = @_;
	my ($qual, $set, $ret, $acl_config);
	
	return 1 unless $permission;

	unless ($acl_config = $Vend::Cfg->{ACL}) {
		die errmsg("ACL configuration missing in [acl tag].");
	}
	
	# match UID on request
	if ($uid) {
		return unless $uid eq $Vend::Session->{username};
	}

	# determine qualifier based on user and corresponding roles
	if ($Vend::Session->{logged_in}) {
		my (@roles, $role_string, $db_roles);

		$roles[0] = 2; # role "authenticated"

		unless ($db_roles = database_exists_ref('user_roles')) {
			die errmsg("Database missing in [acl] tag: %s", 'user_roles');
		}
		
		$set = $db_roles->query($acl_config->{roles_query}, $Vend::Session->{username});
		
		for (@$set) {
			push(@roles, $_->[0]);
		}
		$role_string = join (',', @roles);

		$qual = sprintf($acl_config->{roles_qual}, $Vend::Session->{username}, $role_string);
	} else {
		# anonymous role
		$qual = q{rid = 1};
	}

	# check for proper permission
	my $db_perms;
	my @permissions = ref($permission) eq 'ARRAY' ? @$permission : ($permission);

	unless ($db_perms = database_exists_ref('permissions')) {
		die errmsg("Database missing in [acl] tag: %s", 'permissions');
	}
		
	for my $perm (@permissions) {
		$set = $db_perms->query(qq{select count(*) from permissions where perm = '%s' and $qual}, $perm);

		if ($set->[0]->[0]) {
			$ret = $perm;
			last;
		}
	}

	if ($opt->{reverse}) {
		$ret = ! $ret;
	}

	if ($ret && length($body)) {
		return $body;
	}

	return $ret;
}

1;
