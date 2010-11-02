# WellWell::Compose - WellWell compose routines
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
# Software Foundation, Inc., MA 02110-1301, USA.

package WellWell::Compose;

use strict;
use warnings;

use Vend::Config;
use Vend::Data;
use Vend::Tags;

use WellWell::Engine qw/load_engine/;

use WellWell::Compose::Engine::ITL;
use WellWell::Compose::Engine::Zoom;

Vend::Config::parse_tag('UserTag', 'compose Order template');
Vend::Config::parse_tag('UserTag', 'compose HasEndTag');
Vend::Config::parse_tag('UserTag', 'compose AddAttr');
Vend::Config::parse_tag('UserTag', 'compose MapRoutine WellWell::Compose::compose');

sub dots2hash {
	my ($h, $v, @k) = @_;
	my ($skey);

	while (@k > 1) {
		$skey = shift @k;
		$h->{$skey} ||= {};
		$h = $h->{$skey};
	}
	$h->{shift @k} = $v;
}

sub compose {
	my ($template, $opt, $body) = @_;
	my (%acl, %forms, %engines, $template_file, $container);

	if ($opt->{acl})  {
		# check permissions first
		for my $k (keys %{$opt->{acl}}) {
			dots2hash(\%acl, $opt->{acl}->{$k}, split /\./, $k);
		}

		unless (Vend::Tags->acl('check', $acl{check})) {
			Vend::Tags->deliver({location => Vend::Tags->area($acl{bounce}),
				status => '302 move temporarily'});
			return;							
		}
	}

	if ($opt->{forms}) {
		# process forms first
		for my $k (keys %{$opt->{forms}}) {
			dots2hash(\%forms, $opt->{forms}->{$k}, split /\./, $k);
		}

		my $name;

		for my $k (keys %forms) {
			$name = $forms{$k}->{name};

			if ($::Scratch->{forms}->{$name}) {
				# form intercepted by autoload
				$forms{$k}->{content} = $::Scratch->{forms}->{$name};
			} else {
				$forms{$k}->{content} = Vend::Tags->form({name => $name,
					template => $forms{$k}->{template}});
			}
		}

		# form bounce to another page
		if ($::Scratch->{form_series_bounce}) {
			Vend::Tags->deliver({location => Vend::Tags->area($::Scratch->{form_series_bounce}), status => '302 move temporarily'});
			return;
		}
	}

	if ($opt->{engine}) {
		%engines = %{$opt->{engine}};
	}
	
	$opt->{body} ||= $body;
	# preserve local body even after components.body=, as user might want it
	$opt->{local_body} = $opt->{body};

	if( !$::Variable->{MV_TEMPLATE_DIR} ){
		::logError("MV_TEMPLATE_DIR is not set. [compose] cannot function properly without this variable.");
		return errmsg('Templates not found, please contact site administrator.');
	}

	if( !$::Variable->{MV_COMPONENT_DIR} ){
		::logError("MV_COMPONENT_DIR is not set. [compose] cannot function properly without this variable.");
		return errmsg('Components not found, please contact site administrator.');
	}

	unless( $template_file = $opt->{template_file} ) {
		# locate template
		$template ||= Vend::Tags->control('template', 'main');
		$template_file = "$::Variable->{MV_TEMPLATE_DIR}/$template";

		# read template
		$template_file = Vend::Tags->file($template_file);
	}

	# process attributes ([compose attributes.COMPONENT.OPTION='VALUE'...])
	# COMPONENT => filename in components/
	# OPTION/VALUE => arbitrary option/value
	my (%attributes);

	# automatic attributes
	if ($::Variable->{MV_ATTRIBUTE_AUTO}) {
		my @auto = split(/\s+/, $::Variable->{MV_ATTRIBUTE_AUTO});

		for (@auto) {
			my ($ph, $c) = split(/[=:]/, $_, 2);
			dots2hash(\%attributes, $c, split /\./, $ph);
		}
	}

	if (ref($opt->{attributes}) eq 'HASH') {
		# Interchange's parser splits up only one level of dots, so
		# attributes.foo.bar = "com" ends up as foo.bar => com.
		# We need arbitrary levels.

		for my $k (keys %{$opt->{attributes}}) {
			dots2hash(\%attributes, $opt->{attributes}->{$k}, split /\./, $k);
		}
	}

	# override attributes from CGI variables
	# for example: mv_attribute=htmlhead.title=Homepage
	
	if ($CGI::values{mv_attribute}) {
		for (@{$CGI::values_array{mv_attribute}}) {
			if (/^(.+?)\.(.+?)=(.*)$/) {
				$attributes{$1}->{$2} = $3;
			}
		}
	}

	# automatic components
	if ($::Variable->{MV_COMPONENT_AUTO}) {
		my @auto = split(/\s+/, $::Variable->{MV_COMPONENT_AUTO});
		my %skipauto;

		if ($opt->{skipauto}) {
			for (split(/[,\s]+/, $opt->{skipauto})) {
				$skipauto{$_} = 1;
			}
		}

		for (@auto) {
			my ($ph, $c) = split(/[=:]/, $_, 2); # i.e. body=c1,c2=a2

			for my $sc (reverse split(/,+/, $c)) {
				next if $opt->{skipauto} && $skipauto{$sc};

				if (exists $opt->{components}->{$ph}) {
					$opt->{components}->{$ph} = "$sc $opt->{components}->{$ph}";
				} else {
						$opt->{components}->{$ph} = $sc;
				}
			}
		}
	}

	# determine whether we wrap a container around components
	$container = $::Variable->{COMPOSE_CONTAINER} || $opt->{container};
	
	# process components ([compose components.placeholder='COMP_SPEC'...])
	# placeholder => "{NAME}" within template file
	# COMP_SPEC => "component1=alias1 c2=a2, c3 c4, c5"
	my ($components_file, $component_attributes);

	if (ref($opt->{components}) eq 'HASH') {
		for (keys %{$opt->{components}}) {
			my (@components, @content);

			if ($_ eq 'body' && $CGI::values{mv_components}) {
				# override components 
				@components = split(/[,\s]+/, $CGI::values{mv_components});
			} elsif (ref($opt->{components}->{$_}) eq 'ARRAY') {
				@components = @{$opt->{components}->{$_}};
			} else {
				@components = split(/[,\s]+/, $opt->{components}->{$_});
			}

			for my $comp (@components) {
				my (%var, $type);

				if ($forms{$comp}) {
					# use precalculated form
					push(@content, $forms{$comp}->{content});
					next;
				}

				# TODO support multiple aliases
				my ($name, $alias) = split(/=/, $comp, 2);

				$component_attributes = { 
					$attributes{$name} ? %{$attributes{$name}} : (),
					$attributes{$alias} ? %{$attributes{$alias}} : (),
				};

				# temporarily assign variables for component attributes
				for my $attr (keys %$component_attributes) {
					if (exists $::Variable->{uc($attr)}) {
						$var{uc($attr)} = $::Variable->{uc($attr)};
					}
					$::Variable->{uc($attr)} = $component_attributes->{$attr};
				}

				if ($container) {
					# figure out whether to output class= or id=
					$type = $attributes{$alias||$name}{css_type} || 'class';
				}

				# locate component depending on the engine
				my ($engine_name, $engine, $compobj);
				
				if (exists $engines{$name}) {
					$engine_name = $engines{$name};
				}
				else {
					$engine_name = 'itl';
				}
				delete $Vend::Session->{engine}->{$engine_name};
				unless ($Vend::Session->{engine}->{$engine_name} ||= load_engine($engine_name, database_exists_ref('products')->dbh())) {
					die "Unknown template engine $engine_name\n";
				}

				$engine = $Vend::Session->{engine}->{$engine_name};

				# add component	
				my $component_content;

				if ($_ eq 'body' and $name eq 'local_body' ) {
					$component_content = $opt->{local_body};
				} else {
					if ($compobj = $engine->locate_component($name)) {
						$component_content = $compobj->process($component_attributes);

						unless (defined $component_content && $name ne 'local_body') {
							::logError("Error processing component $name with $engine_name.");
							Vend::Tags->error({name => 'component', set => "Error processing component $name."});
							next;
						}
					}
					elsif ($name ne 'local_body') {
						::logError("Component $name not found for $engine_name.");
						Vend::Tags->error({name => 'component', set => "Component $name not found."});
						next;
					}
				}
				
				my $wrap = 0;

				if ($container) {
					if ($component_content =~ /\S/) {
						# check whether container is explicitly suppressed
						unless (exists $component_attributes->{container}
							&& $component_attributes->{container} eq '') {
							$wrap = 1;
						}
					}
					elsif (! $component_attributes->{skipblank}) {
						# even wrap empty components
						$wrap = 1;
					}	
				}

				if ($wrap) {
					push (@content,
						qq{<div $type='$name'>} .
				    	( $alias ? qq{<div $type='$alias'>} : '' ) .
					    $component_content .
					    ( $alias ? qq{</div>} : '' ) .
					    q{</div>});
				}
				else {
					push (@content, $component_content);
				}

				# reset variables
				for my $attr (keys %$component_attributes) {
					if (exists $var{uc($attr)}) {
						$::Variable->{uc($attr)} = $var{uc($attr)};
					} else {
						delete $::Variable->{uc($attr)};
					}
				}
			}

			$opt->{$_} = join('', @content);
		}
	}

	# compose
	Vend::Tags->uc_attr_list({hash => $opt, body => $template_file});	
}
	
1;
