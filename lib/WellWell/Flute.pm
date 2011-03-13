# WellWell::Flute - WellWell template parsing routines
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

package WellWell::Flute;

use strict;
use warnings;

use XML::Twig;
use Rose::DB::Object::QueryBuilder qw(build_select);

use WellWell::Flute::Increment;

use Vend::Config;
use Vend::Data;
use Vend::Tags;

Vend::Config::parse_tag('UserTag', 'flute MapRoutine WellWell::Flute::flute');
Vend::Config::parse_tag('UserTag', 'flute Order function name');
Vend::Config::parse_tag('UserTag', 'flute AddAttr');
Vend::Config::parse_tag('UserTag', 'flute HasEndTag');

# flute - [flute] tag

sub flute {
	my ($function, $name, $opt, $body) = @_;

	if ($function eq 'init') {
		unless (exists $::Scratch->{flute}) {
			Vend::Tags->tmp('flute', {});
		}

		$::Scratch->{flute}->{$name}->{html} = $body;
		$::Scratch->{flute}->{$name}->{object} = parse_template($body, $opt->{specs});
	}
	
	if ($function eq 'display') {
		my ($sref, $bref, $sql, $sth, $bind, %columns, $row, $key, $value,
			$att_name, $att_spec, $att_tag_name, $att_tag_spec, %att_tags, $att_val,
			$lel, %paste_pos, $rep_str);

		unless ($sref = $::Scratch->{flute}->{$name}->{object}) {
			die "Missing template $name\n";
		}

		$bref = $opt->{build};
		$bref->{dbh} = database_exists_ref('products')->dbh();
		$bref->{query_is_sql} = 1;

		# now determine which fields are needed
		my %tables;
		
		while (($key, $value) = each %{$sref->{params}->{$name}->{hash}}) {
			if (exists $value->{table}) {
				$tables{$value->{table}} = 1;
				push @{$bref->{columns}->{$value->{table}}}, $value->{field} || $key;
			}
		}

		unless (keys %tables) {
			Vend::Tags->error({name => 'flute', set => 'Missing tables in specification.'});
			return;
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
		
		my $row_pos = 0;
		
		while ($row = $sth->fetchrow_hashref) {
			# now fill in params
			while (($key, $value) = each %{$sref->{params}->{$name}->{hash}}) {
				$rep_str = $row->{$value->{field} || $key};

				if ($value->{increment}) {
					$rep_str = $value->{increment}->value();
				}
				
				if ($value->{subref}) {
					$rep_str = $value->{subref}->($row);
				}
				
				if ($value->{filter}) {
					$rep_str = Vend::Tags->filter({op => $value->{filter}, body => $rep_str});
				}
				
				for my $elt (@{$value->{elts}}) {
					if ($elt->{flute_rep_sub}) {
						# call subroutine to handle this element
						$elt->{flute_rep_sub}->($elt, $rep_str, $row);
					}
					elsif ($elt->{flute_rep_att}) {
						# replace attribute instead of embedded text (e.g. for <input>)
						$elt->set_att($elt->{flute_rep_att}, $rep_str);
					}
					elsif ($elt->{flute_rep_elt}) {
						# use provided text element for replacement
						$elt->{flute_rep_elt}->set_text($rep_str);
					}
					else {
						$elt->set_text($rep_str);
					}

					# replace attributes on request
					if ($value->{attributes}) {
						while (($att_name, $att_spec) = each %{$value->{attributes}}) {
							if (exists ($att_spec->{filter})) {
								# derive tags from current record
								if (exists ($att_spec->{filter_tags})) {
									while (($att_tag_name, $att_tag_spec) = each %{$att_spec->{filter_tags}}) {
										$att_tags{$att_tag_name} = $row->{$att_tag_spec};
									}
								}
								else {
									%att_tags = ();
								}
								
								$att_val = Vend::Interpolate::filter_value($att_spec->{filter}, undef, \%att_tags, $att_spec->{filter_args});
								$elt->set_att($att_name, $att_val);
							}
						}
					}
				}
			}
			
			$row_pos++;
			
			# now add to the template
			my $subtree = $lel->copy();

			# alternate classes?
			if ($sref->{lists}->{$name}->[2]->{alternate}) {
				my $idx = $row_pos % $sref->{lists}->{$name}->[2]->{alternate};
				
				$subtree->set_att('class', $sref->{lists}->{$name}->[1]->[$idx]);
			}
			
			$subtree->paste(%paste_pos);

			# call increment functions
			for my $inc (@{$sref->{increments}->{$name}->{array}}) {
				$inc->{increment}->increment();
			}
		}

		# replacements for simple values
		while (($key, $value) = each %{$sref->{values}}) {
			for my $elt (@{$value->{elts}}) {
				if ($value->{scope} eq 'scratch') {
					$rep_str = $::Scratch->{$key};
				}
				else {
					$rep_str = $value->{value};
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
	my ($twig, $xml, $object, $list);

	$object = {specs => $specs, lists => {}, params => {}};
		
	$twig = new XML::Twig (twig_handlers => {_all_ => sub {parse_handler($_[1], $object)}});
	$xml = $twig->safe_parse($template);

	unless ($xml) {
		die "Invalid HTML template: $template\n";
	}

	# examine list on alternates
	for my $name (keys %{$object->{lists}}) {
		$list = $object->{lists}->{$name};

		if (@{$list->[1]} > 1) {
			$list->[2]->{alternate} = @{$list->[1]};
		}
	}
	
	$object->{xml} = $xml;
	return $object;
}

# parse_handler - Callback for HTML elements

sub parse_handler {
	my ($elt, $sref) = @_;
	my ($gi, @classes, @static_classes, $class, $name, $sob, $elt_text);

	$gi = $elt->gi();

	# weed out "static" classes
	for my $class (split(/\s+/, $elt->att('class'))) {
		if (exists $sref->{specs}->{class}->{$class}) {
			push @classes, $class;
		}
		else {
			push @static_classes, $class;
		}
	}
	
	for my $class (@classes) {
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
			if (exists $sref->{lists}->{$name}) {
				# record static classes
				push (@{$sref->{lists}->{$name}->[1]}, join(' ', @static_classes));
				
				# discard repeated lists
				$elt->cut();
				return;
			}
			
			$sob->{elts} = [$elt];

			$sref->{lists}->{$name} = [$sob, [join(' ', @static_classes)]];
			return $sref;
		}

		if (exists $sref->{lists}->{$sob->{list}}) {
			return $sref;
		}

		if ($sob->{type} eq 'param') {
			push (@{$sob->{elts}}, $elt);

			if ($gi eq 'input') {
				# replace value attribute instead of text
				$elt->{flute_rep_att} = 'value';
			} elsif ($gi eq 'select') {
				$elt->{flute_rep_sub} = \&set_selected;
			} elsif (! $elt->contains_only_text()) {
				# contains real elements, so we have to be careful with
				# set text and apply it only to the first PCDATA element
				if ($elt_text = $elt->first_child('#PCDATA')) {
					$elt->{flute_rep_elt} = $elt_text;
				}
			}
			
			if ($sob->{sub}) {
				# determine code reference for named function
				my $subref = $Vend::Cfg->{Sub}{$sob->{sub}} || $Global::GlobalSub->{$sob->{sub}};

				if (exists $sob->{scope} && $sob->{scope} eq 'element') {
					$elt->{flute_rep_sub} = $subref;
				} else {
					$sob->{subref} = $subref;
				}
			}
			
			$sref->{params}->{$sob->{list}}->{hash}->{$name} = $sob;
			push(@{$sref->{params}->{$sob->{list}}->{array}}, $sob);
		} elsif ($sob->{type} eq 'increment') {
			# increments
			push (@{$sob->{elts}}, $elt);

			# create increment object and record it for increment updates
			$sob->{increment} = new WellWell::Flute::Increment;
			push(@{$sref->{increments}->{$sob->{list}}->{array}}, $sob);

			# record it for increment values
			$sref->{params}->{$sob->{list}}->{hash}->{$name} = $sob;
		} elsif ($sob->{type} eq 'value') {
			push (@{$sob->{elts}}, $elt);
			$sref->{values}->{$name} = $sob;
		} else {
			return $sref;
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
