UserTag symlink Order old new
UserTag symlink AddAttr
UserTag symlink Routine <<EOR
sub {
	my ($old, $new, $opt) = @_;
	my ($dirs, $link, $ret);

	unless (allowed_file($new)) {
		log_file_violation($new);
		return;
	}

	if ($opt->{relative}) {
		unless ($new =~ m%^../%) {
			$dirs = split(m{/+}, $new);

			if ($dirs > 1) {
				$old = (('../') x ($dirs - 1)) . $old;
			}
		}
	}
	else {
		$old = join('/', $Vend::Cfg->{VendRoot}, $old);
	}


	if ($opt->{erase_existing_link}) {
		if (-l $new) {
			# symlink exists already
			$link = readlink($new);

			if ($link eq $old) {
			 	return 1;
			}

			my $prefix = (split(m{/+}, $new))[0];

			unless ($ret = $Tag->unlink_file($new, $prefix)) {
				return;
			}
		}
	}
	elsif ($opt->{verify_existing_link}) {
		if (-l $new) {
			# symlink exists already
			$link = readlink($new);

			if ($link eq $old) {
			 	return 1;
			}

			Log("Conflicting symlink: $link instead of $old.");
			return;
		}
	}
		
	return symlink($old, $new);
}
EOR
