# 
# Syntax: [acl check]
#
# function=check permission=enter_titles
# function=check permission.0=enter_titles_without_approval 
# 	permission.1=enter_titles
# function=check permission=change_own_titles uid="[scratch entered_by]"
#
# Without body it returns first matching permission or empty string if no
# permission is granted.
#
# With body it returns the body if permission is granted.
#

UserTag acl Order function permission uid
UserTag acl AddAttr
UserTag acl HasEndTag
UserTag acl Routine <<EOR
sub {
	my ($function, $permission, $uid, $opt, $body) = @_;
	my ($qual, $set, $ret);

	return 1 unless $permission;

	$Tag->perl({tables => "roles user_roles permissions"});

	# match UID on request
	if ($uid) {
		return unless $uid == $Session->{username};
	}

	# determine qualifier based on user and corresponding roles
	if ($Session->{logged_in}) {
		my (@roles, $role_string);

		$roles[0] = 2; # role "authenticated"

		$set = $Db{user_roles}->query(qq{select rid from user_roles where uid = $Session->{username}});
		for (@$set) {
			push(@roles, $_->[0]);
		}
		$role_string = join (',', @roles);

		$qual = qq{(uid = $Session->{username} or rid in ($role_string))}; 
	} else {
		# anonymous role
		$qual = q{rid = 1};
	}

	# check for proper permission
	my @permissions = ref($permission) eq 'ARRAY' ? @$permission : ($permission);

	for my $perm (@permissions) {
		$set = $Db{permissions}->query(qq{select count(*) from permissions where perm = '%s' and $qual}, $perm);

		if ($set->[0]->[0]) {
			$ret = $perm;
			last;
		}
	}

	if ($opt->{reverse}) {
		$ret = ! $ret;
	}

	if ($ret && $body =~ /\S/) {
		return $body;
	}

	return $ret;
}
EOR
