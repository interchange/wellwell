# WellWell::Plugin - WellWell plugin routines
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

package WellWell::Plugin;

use vars qw/@ISA @EXPORT_OK/;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/plugin_scan plugin_enable/;
	
sub plugin_scan {
	my ($dbif, @dirs) = @_;
	my (@plugins, $dirname, $infofile, $plugininfo, $dbref);
	my ($plugin, $pluginrec);
	my ($sth, $href);
	my (%plugins);
	
	# read current plugins from database
	$sth = $dbif->process('select * from plugins');

	while ($href = $sth->fetchrow_hashref()) {
		$plugins{$href->{name}} = $href;
	}
	
	for my $dir (@dirs) {
		opendir(PLUGINS, $dir);
		while ($dirname = readdir(PLUGINS)) {
			next unless -d "plugins/$dirname";
			next if $dirname =~ /^\./;

			# info file ?
			$infofile = "plugins/$dirname/$dirname.info";
			if (-f $infofile) {
				$plugininfo = plugin_get_info($infofile);

				if (exists $plugins{$dirname}) {
					# existing plugin
				}
				else {
					# new plugin
					$pluginrec = {name => $dirname,
								  version => $plugininfo->{version},
								  label => $plugininfo->{label} || $dirname,
								  active => undef};

					$dbif->insert('plugins', %$pluginrec);
					
					$plugins{$dirname} = $pluginrec;
				}
			}

			if ($plugininfo->{require}) {
				my @modules;

				@modules = split(/\s*,\s*/, $plugininfo->{require});

				for (@modules) {
#					warn("Require $_.\n");
				}
			}
		}
		closedir(PLUGINS);
	}

	return \%plugins;
}

sub plugin_enable {
	my ($dbif, $plugin) = @_;

	$dbif->update('plugins', 'name = ' . $dbif->quote($plugin), active => 1);
}

sub plugin_disable {
	my ($dbif, $plugin) = @_;

	$dbif->update('plugins', 'name = ' . $dbif->quote($plugin), active => 0);
}

sub plugin_get_info {
	my ($infofile) = @_;
	my %info;
	
	open(INFOFILE, $infofile)
		|| die "Failed to open plugin info file $infofile\n";
	while (<INFOFILE>) {
		chomp;
		# skip emptylines and comments
		next if ! /\S/;
		next if /^\s*#/;
		next unless /=/;

		my ($key, $value) = split(/\s*=\s*/, $_, 2);
		$info{$key} = $value;
	}
	close(INFOFILE);

	return \%info;
}

1;
