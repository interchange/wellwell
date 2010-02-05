# Vend::Panel - Interchange Panels
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

package Vend::Panel;

use strict;
use warnings;

use Vend::Config;
use Vend::Tags;
use Vend::Data;

# define [panel] tag
Vend::Config::parse_tag('UserTag', 'panel Order table columns');
Vend::Config::parse_tag('UserTag', 'panel HasEndTag');
Vend::Config::parse_tag('UserTag', 'panel AddAttr');
Vend::Config::parse_tag('UserTag', 'panel MapRoutine Vend::Panel::panel');

sub new {
	my ($class, @parms) = @_;
	my $self = {@parms};

	bless $self;
}

sub panel {
	my ($table, $columns, $opt, $body) = @_;
	my ($panel, $db, $set, @out, @cols, $colstr);

	$panel = new Vend::Panel;

	if ($body =~ /\S/) {
		$panel->parse_simple($body);
	}
	
	unless ($columns) {
		# pull up complete table
		unless ($db = database_exists_ref($table)) {
			die ::errmsg('[panel] cannot access table: %s', $table), "\n";
		}

		# derive columns from template variables
		for (keys %{$panel->{variables}}) {
			if ($db->column_exists($_)) {
				push (@cols, $_);
			}
		}

		if (@cols) {
			$colstr = join(',', @cols);
		}
		else {
			return $body;
		}
		
		$set = $db->query({sql => qq{select $colstr from $table}, hashref => 1});

		for my $row (@$set) {
			for my $fltvar (%{$opt->{filters}}) {
				$row->{$fltvar} = Vend::Tags->filter({op => $opt->{filters}->{$fltvar}, body => $row->{$fltvar}});
			}
			push(@out, $panel->fill_simple($row));
		}
	}

	return join('', @out);
}

sub parse_simple {
	my ($self, $input) = @_;

	pos $input = 0;

	$self->{tokens} = [];
	$self->{variables} = {};
	
	while (pos $input < length $input) {
		if ($input =~ m{ \G  (.*?)?\{([A-Z_]+)\} }gcxms) {
			if (defined $1) {
				push (@{$self->{tokens}}, $1);
			}
			push (@{$self->{tokens}}, '');
			push (@{$self->{variables}->{lc($2)}}, $#{$self->{tokens}});
		}
		else {
			push (@{$self->{tokens}}, substr($input, pos($input)));
			last;
		}
	}

	return 1;
}

sub fill_simple {
	my ($self, $hash) = @_;
	my ($out, $tokref);

	@$tokref = @{$self->{tokens}};

	for (keys %{$self->{variables}}) {
		for my $pos (@{$self->{variables}->{$_}}) {
			$tokref->[$pos] = $hash->{$_};
		}
	}

	return join('', @$tokref);
}

1;

