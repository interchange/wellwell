# WellWell::Data - WellWell database routines
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

package WellWell::Data;

use strict;
use warnings;

use Rose::DB::Object::Loader;

use Vend::Data;

sub prepare_database {
	my ($userdb_ref, $users_table, %dbif);
	my ($users_key, $users_key_numeric);
	
	$userdb_ref = $Vend::Cfg->{UserDB};
	$users_table = $userdb_ref->{database} || 'userdb';

	unless ($dbif{users} = database_exists_ref($users_table)) {
		die ::errmsg('Database missing: %s', $users_table);
	}

	# "username" field which ends up in $Session->{username}
	
	$users_key = $dbif{users}->config('KEY');
	$users_key_numeric = $dbif{users}->numeric($users_key);

	# in addition to the user database we need the following tables:
	# user_roles and permissions - with corresponding field for username
	
	for my $table (qw/user_roles permissions/) {
		unless ($dbif{$table} = database_exists_ref($table)) {
			die ::errmsg('Database missing: %s', $table);
		}

		unless ($dbif{$table}->column_exists($users_key)) {
			die ::errmsg('Column %s missing in %s', $users_key, $table);
		}
	}

	# determine query for user's roles
	my ($roles_query, $roles_qual);

	if ($users_key_numeric) {
		$roles_query = qq{select rid from user_roles where $users_key = %s};
	}
	else {
		$roles_query = qq{select rid from user_roles where $users_key = '%s'};
	}

	$roles_qual = qq{($users_key = '%s' or rid in (%s))};
	
	$Vend::Cfg->{ACL}->{roles_query} = $roles_query;
	$Vend::Cfg->{ACL}->{roles_qual} = $roles_qual;	

	return;
}

sub make_classes {
	my ($catalog) = @_;
	my (%args, $loader, @classes, @sqlparms);

	@sqlparms = split(/\s+/, $::Variable->{SQLDSN});

	if (@sqlparms == 1) {
		push (@sqlparms, $::Variable->{SQLUSER}, $::Variable->{SQLPASS});
	}

	($args{db_dsn}, $args{db_username}, $args{db_password}) = @sqlparms;
		
	$args{class_prefix} = 'Catalog::Database::' . ucfirst($catalog);
	$args{include_tables} = ['plugins'];
	$loader = new Rose::DB::Object::Loader (%args);

	@classes = $loader->make_classes();

	return @classes;
}

1;
