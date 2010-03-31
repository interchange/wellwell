# WellWell::Menu - WellWell Menu Functions/Tags
#
# Copyright (C) 2009,2010 Stefan Hornburg (Racke) <racke@linuxia.de>.
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
	my ($db_menus, $tree);
	
	if ($opt->{ref}) {
		$set = $opt->{ref};
	}
	else {
		$db_menus = database_exists_ref('menus');
	
		$name_qtd = $db_menus->quote($name);

		@fields = qw/code name url parent permission/;
		
		$fstr = join(',', @fields);
		
		$set = $db_menus->query({sql => qq{select $fstr from menus where menu_name = $name_qtd order by parent asc, weight desc, code}, hashref => 1});
	}
	
	for (@$set) {
		next if $_->{permission} && ! Vend::Tags->acl('check', $_->{permission});
		$tree ||= $_->{parent};
		push(@entries, $_);
	}

	if ($opt->{hooks}) {
		my @hook_entries = Vend::Tags->call_hooks('menu', 'collect', $name, $opt);

		for (@hook_entries) {
			next unless ref($_) eq 'HASH';
			push(@entries, $_);
		}
	}
	
	return build_entries(\@entries, $opt, $tree);
}

sub build_entries {
	my ($entries_ref, $opt, $tree) = @_;
	my (@out, $ref, $base_url, $uri, $cur_level, $form, $selected);
	
	if ($opt->{selected}) {
		$base_url = $Vend::Session->{last_url};
		$base_url =~ s%^/%%;
	}

	if ($tree) {
		$entries_ref = sort_tree_entries($entries_ref);
		$cur_level = $entries_ref->[0]->{level};
	}

	for (my $i = 0; $i < @$entries_ref; $i++) {
		$ref = $entries_ref->[$i];

		if ($cur_level) {
			if ($ref->{level} > $cur_level) {
				push(@out, '<ul>');
			}
			elsif ($ref->{level} < $cur_level) {
				push(@out, ('</ul>') x ($cur_level - $ref->{level}));
			}

			$cur_level = $ref->{level};
		}
		
		if ($ref->{url}) {
			if ($opt->{selected}) {
				if (index($base_url, $ref->{url}) == 0) {
					$selected = qq{ class="$opt->{selected}"};
				}
				else {
					$selected = '';
				}
			}

			if (ref($ref->{form}) eq 'HASH') {
				$form = join("\n", map {"$_=$ref->{form}->{$_}"} keys(%{$ref->{form}}));
			}
			else {
				$form = '';
			}
			
			$uri = Vend::Tags->area({href => $ref->{url}, form => $form});
			push(@out, qq{<li$selected><a href="$uri">$ref->{name}</a></li>});
		}
		else {
			push(@out, qq{<li>$ref->{name}</li>});
		}
	}

	if ($cur_level > 1) {
		push(@out, ('</ul>') x ($cur_level -1));
	}
	
	return q{<ul>} . join('', @out) . q{</ul>};
}

sub sort_tree_entries {
	my $entries_ref = shift;
	my ($ref, @parents);
	my %menu_tree = ();
	my $tree_ref = [];

	# first pass to establish tree relationships
	for (my $i = 0; $i < @$entries_ref; $i++) {
		$ref = $entries_ref->[$i];

		if ($ref->{parent} > 0) {
			# this is a descendant, register it with the parent
			push @{$menu_tree{$ref->{parent}}}, $ref;
		} else {
			# top level item
			push (@parents, $ref);
								
			unless (exists $menu_tree{$ref->{code}}) {
				$menu_tree{$ref->{code}} = [];
			}
		}
	}

	# second pass to order tree entries
	my (%seen, @children, @nodes, @levels);
		
	for (my $i = 0; $i < @parents; $i++) {
		$ref = $parents[$i];
		$ref->{level} = 1;
		$seen{$ref->{code}} = 1;
		push(@$tree_ref, $ref);

		@children = @{$menu_tree{$ref->{code}}};
		@levels = ((2) x scalar(@children));
			
		@nodes = @children;
			
		while ($ref = shift(@nodes)) {
			$ref->{level} = shift(@levels);
				
			if (exists $seen{$ref->{code}}) {
				::logError("Circular dependency in menu.");
				next;
			}

			$seen{$ref->{code}} = 1;
			push(@$tree_ref, $ref);

			# add descendants to the stack
			if (exists $menu_tree{$ref->{code}}) {
				@children = @{$menu_tree{$ref->{code}}};
				push(@levels, (($ref->{level} + 1) x scalar(@children)));
				push(@nodes, @children);
			}
		}
	}

	return $tree_ref;
}

1;
