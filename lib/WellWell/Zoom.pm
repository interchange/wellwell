# WellWell::Zoom - WellWell template parsing routines
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

package WellWell::Zoom;

use strict;
use warnings;

use XML::Twig;
use Rose::DB::Object::QueryBuilder qw(build_select);

use Vend::Config;
use Vend::Data;
use Vend::Tags;

Vend::Config::parse_tag('UserTag', 'zoom MapRoutine WellWell::Zoom::zoom');
Vend::Config::parse_tag('UserTag', 'zoom Order function name');
Vend::Config::parse_tag('UserTag', 'zoom AddAttr');
Vend::Config::parse_tag('UserTag', 'zoom HasEndTag');

# zoom - [zoom] tag

sub zoom {
	my ($function, $name, $opt, $body) = @_;

	if ($function eq 'init') {
		unless (exists $::Scratch->{zoom}) {
			Vend::Tags->tmp('zoom', {});
		}

		$::Scratch->{zoom}->{$name}->{html} = $body;
		$::Scratch->{zoom}->{$name}->{object} = parse_template($body, $opt->{specs});
	}
	
	if ($function eq 'display') {
		my ($sref, $bref, $sql, $sth, $bind, %columns, $row, $key, $value, $lel, %paste_pos, $rep_str);

		unless ($sref = $::Scratch->{zoom}->{$name}->{object}) {
			die "Missing template $name\n";
		}

		$bref = $opt->{build};
		$bref->{dbh} = database_exists_ref('products')->dbh();
		$bref->{query_is_sql} = 1;

		# now determine which fields are needed
		while (($key, $value) = each %{$sref->{params}->{$name}->{hash}}) {
			if (exists $value->{table}) {
				push @{$bref->{columns}->{$value->{table}}}, $value->{field} || $key;
			}
		}

		($sql, $bind) = build_select(%$bref);

		$sth = $bref->{dbh}->prepare($sql);
		$sth->execute(@$bind);

		$lel = $sref->{lists}->{$name}->[0]->{elts}->[0];

		if ($lel->is_last_child()) {
			%paste_pos = (last_child => $lel->parent());
		}
		else {
			%paste_pos = (before => $lel->next_sibling());
		}

		$lel->cut();
			
		while ($row = $sth->fetchrow_hashref) {
			# now fill in params
			while (($key, $value) = each %{$sref->{params}->{$name}->{hash}}) {
				$rep_str = $row->{$value->{field} || $key};

				if ($value->{subref}) {
					$rep_str = $value->{subref}->($row);
				}
				
				if ($value->{filter}) {
					$rep_str = Vend::Tags->filter({op => $value->{filter}, body => $rep_str});
				}
				
				for my $elt (@{$value->{elts}}) {
					if ($elt->{zoom_rep_sub}) {
						# call subroutine to handle this element
						$elt->{zoom_rep_sub}->($elt, $rep_str);
					}
					elsif ($elt->{zoom_rep_att}) {
						# replace attribute instead of embedded text (e.g. for <input>)
						$elt->set_att($elt->{zoom_rep_att}, $rep_str);
					}
					elsif ($elt->{zoom_rep_elt}) {
						# use provided text element for replacement
						$elt->{zoom_rep_elt}->set_text($rep_str);
					}
					else {
						$elt->set_text($rep_str);
					}
				}
			}
	
			# now add to the template
			my $subtree = $lel->copy();
	
			$subtree->paste(%paste_pos);
		}

		# replacements for simple values
		while (($key, $value) = each %{$sref->{values}}) {
			for my $elt (@{$value->{elts}}) {
				if ($value->{scope} eq 'scratch') {
					$rep_str = $::Scratch->{$key};
				}
				
				if ($value->{filter}) {
					$rep_str = Vend::Tags->filter({op => $value->{filter}, body => $rep_str});
				}
				
				$elt->set_text($rep_str);
			}
		}
				
		return $sref->{xml}->sprint;
	}
}

# parse_template - Parse (HTML) template according to specifications

sub parse_template {
	my ($template, $specs) = @_;
	my ($twig, $xml, $object);

	$object = {specs => $specs, lists => {}, params => {}};
		
	$twig = new XML::Twig (twig_handlers => {_all_ => sub {parse_handler($_[1], $object)}});
	$xml = $twig->safe_parse($template);

	unless ($xml) {
		die "Invalid HTML template: $template\n";
	}

	$object->{xml} = $xml;
	return $object;
}

# parse_handler - Callback for HTML elements

sub parse_handler {
	my ($elt, $sref) = @_;
	my ($gi, $class, $name, $sob, $elt_text);

	$gi = $elt->gi();
	$class  = $elt->att('class');

	if (defined $class && exists $sref->{specs}->{class}->{$class}) {
		$sob = $sref->{specs}->{class}->{$class};
		$name = $sob->{name} || $class;

		if ($sob->{permission}) {
			unless (Vend::Tags->acl('check', $sob->{permission})) {
				# no permission for this document part
				$elt->cut();
				return;
			}
		}
		
		if ($sob->{type} eq 'list') {
			$sob->{elts} = [$elt];

			$sref->{lists}->{$name} = [$sob];
		}
		elsif ($sob->{type} eq 'param') {
			push (@{$sob->{elts}}, $elt);

			if ($gi eq 'input') {
				# replace value attribute instead of text
				$elt->{zoom_rep_att} = 'value';
			}
			elsif ($gi eq 'select') {
				$elt->{zoom_rep_sub} = \&set_selected;
			}
			elsif (! $elt->contains_only_text()) {
				# contains real elements, so we have to be careful with
				# set text and apply it only to the first PCDATA element
				if ($elt_text = $elt->first_child('#PCDATA')) {
					$elt->{zoom_rep_elt} = $elt_text;
				}
			}
			
			if ($sob->{sub}) {
				# determine code reference for named function
				my $subref = $Vend::Cfg->{Sub}{$sob->{sub}} || $Global::GlobalSub->{$sob->{sub}};

				if (exists $sob->{scope} && $sob->{scope} eq 'element') {
					$elt->{zoom_rep_sub} = $subref;
				}
				else {
					$sob->{subref} = $subref;
				}
			}
			
			$sref->{params}->{$sob->{list}}->{hash}->{$name} = $sob;
			push(@{$sref->{params}->{$sob->{list}}->{array}}, $sob);
		}
		elsif ($sob->{type} eq 'value') {
			push (@{$sob->{elts}}, $elt);
			$sref->{values}->{$name} = $sob;
		}
		else {
			next;
		}
	}

	return $sref;
}

# set_selected - Set selected value in a dropdown menu

sub set_selected {
	my ($elt, $value) = @_;
	my (@children, $eltval);

	@children = $elt->children('option');

	for my $node (@children) {
		$eltval = $node->att('value');

		unless (length($eltval)) {
			$eltval = $node->text();
		}
		
		if ($eltval eq $value) {
			$node->set_att('selected', 'selected');
		}
		else {
			$node->del_att('selected', '');
		}
	}
}

1;
