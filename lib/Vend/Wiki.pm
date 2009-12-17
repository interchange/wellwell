# Vend::Wiki - Interchange Wiki
#
# Copyright (C) 2004-2009 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package Vend::Wiki;

use strict;
use warnings;

use Vend::Config;
use Vend::Tags;

use Wiki::Toolkit;

# setup wiki configuration directive
Vend::Config::parse_directive('Wiki', 'Wiki wiki');

# define [wiki] tag
Vend::Config::parse_tag('UserTag', 'wiki Order function');
Vend::Config::parse_tag('UserTag', 'wiki HasEndTag');
Vend::Config::parse_tag('UserTag', 'wiki AddAttr');
Vend::Config::parse_tag('UserTag', 'wiki MapRoutine Vend::Wiki::wiki');

# define [wiki] global sub for catalog actions
Vend::Config::parse_subroutine('GlobalSub', 'wiki Vend::Wiki::action');

our %wiki;

sub new {
	my ($class, @parms) = @_;
	my $self = {@parms};

	bless $self;

	if ($self->{backend} eq 'sqlite') {
		unless (-f $self->{dbname}) {
			# create SqLite file
			require Wiki::Toolkit::Setup::SQLite;
			Wiki::Toolkit::Setup::SQLite::setup($self->{dbname});
		}
		require Wiki::Toolkit::Store::SQLite;
		$self->{store} = new Wiki::Toolkit::Store::SQLite(dbname => $self->{dbname});
	}

	# create Wiki::Toolkit formatter(s)
	if ($self->{formatter}) {
		my @formatters;
		
		# single or multiple formatter(s) ?
		@formatters = keys %{$self->{formatter}};

		if (@formatters > 1) {
			my (%parms, $fmt);
			
			for (@formatters) {
				$fmt = $self->{formatter}->{$_};
				$self->load_formatter($fmt);
				$parms{$_} = $fmt->{object};
			}
			require Wiki::Toolkit::Formatter::Multiple;

		    $self->{formatter_object} = Wiki::Toolkit::Formatter::Multiple->new(%parms);
		}
		else {
			my ($fmt);
			
			$fmt = $self->{formatter}->{$formatters[0]};
			$self->load_formatter($fmt);
			$self->{formatter_object} = $fmt->{object};
		}
	}
	else {
		require Wiki::Toolkit::Formatter::Default;
		$self->{formatter_object} = new Wiki::Toolkit::Formatter::Default(node_prefix => '?page=');
	}
	
	# create Wiki::Toolkit object
	$self->{object} = new Wiki::Toolkit(store => $self->{store},
										formatter => $self->{formatter_object});
										
	return $self;
}
	
sub wiki {
	my ($function, $opt, $body) = @_;
	my ($ret, $name);

	# default name for the wiki is just wiki
	$name = $opt->{name} || 'wiki';
	
	unless (exists $wiki{$name}) {
		# initialize Wiki
		unless (exists $Vend::Cfg->{Wiki}->{$name}) {
			# Wiki not defined
			return 'WIKI_NOT_DEFINED';
		}
		
		$wiki{$name} = new Vend::Wiki(%{$Vend::Cfg->{Wiki}->{$name}});
	}

	if ($function eq 'create_page') {
		$ret = $wiki{$name}->create_page($opt->{page}, $opt->{content});
		return $ret;
	}

	if ($function eq 'modify' || $function eq 'modify_page') {
		$ret = $wiki{$name}->modify_page($opt->{page}, $opt->{content}, $opt->{checksum});
		return $ret;
	}
	
	if ($function eq 'display' || $function eq 'display_page') {
		my %page;

		if ($body) {
			# run templating on page
			%page = $wiki{$name}->display_page($opt->{page}, undef, 'raw');
			return Vend::Tags->uc_attr_list({body => $body, hash => \%page});
		}
		else {
			# just return page content
			return $wiki{$name}->display_page($opt->{page});
		}
	}
	
	if ($function eq 'list') {
		 my @nodes = $wiki{$name}->list_pages();

		 if ($body) {
			 # run templating on page list
			 my @list = map {Vend::Tags->uc_attr_list({body => $body,
													   hash => {page => $_}})} @nodes;
			 return join('', @list);
		 } elsif (wantarray) {
			 return @nodes;
		 }
		 else {
			 return join(',', @nodes);
		 }
	}
	
	return $function;
}

# create Wiki page
#
# @param name page name
# @param content page content

sub create_page {
	my ($self, $name, $content) = @_;
	my ($ret);
	
	$ret = $self->{object}->write_node($name, $content);

	unless ($ret) {
		::logError("Failed to create page $name.");
	}
	
	return $ret;
}

# modify Wiki page
sub modify_page {
	my ($self, $name, $content, $checksum) = @_;
	my ($ret);
	
	$ret = $self->{object}->write_node($name, $content, $checksum);

	unless ($ret) {
		die "Page modification failed.";
	}
}

## @method retrieve_page($name, $version)
#
# Retrieves Wiki page.
#
# @param name page name
# @param version page version

sub retrieve_page {
	my ($self, $name, $version) = @_;
	my (%node);

	if ($name =~ /\S/ && $self->{object}->node_exists($name)) {
		if ($version) {
			%node = $self->{object}->retrieve_node({name => $name, version => $version});
		}
		else {
			%node = $self->{object}->retrieve_node($name);
		}
		return %node;
	}

	return;
}

## @method display_page($name, $version, $format)
# Displays Wiki page.
#
# @param name page name
# @param version page version
# @param format page format

sub display_page {
	my ($self, $name, $version, $format) = @_;
	my (%node);

	if ($name =~ /\S/ && $self->{object}->node_exists($name)) {
		if ($version) {
			%node = $self->{object}->retrieve_node({name => $name, version => $version});
		}
		else {
			%node = $self->{object}->retrieve_node($name);
		}

		if ($format ne 'raw') {
			return $self->{object}->format($node{content}, $node{metadata});
		}

		return %node;
	}
	else {
		# boilerplate message for missing pages
		return ::errmsg(q{This page does not exist yet. You can create a new empty page.});
	}
}

# list Wiki pages
sub list_pages {
	my ($self) = @_;
	my (@pages);

	@pages = $self->{object}->list_all_nodes();
	return @pages;
}

# load formatter
sub load_formatter {
	my ($self, $fmt) = @_;

	eval "require $fmt->{class}";
	if ($@) {
		die "Failed to load $fmt->{class}: $@\n";
	}
	eval {
		$fmt->{object} = $fmt->{class}->new (node_prefix => '?page=');
	};
	if ($@) {
		die "Failed to instantiate $fmt->{class}\n";
	}

	return $fmt->{object};
}

# default ActionMap for wiki
sub action {
 	my ($path) = @_;
	my ($action, $url, $page, $name, $key, $value);
	
 	($action, $url) = split(m{/+}, $path, 2);

	# examine configuration for wiki name and relay to configured page
	while (($key, $value) = each %{$Vend::Cfg->{Wiki}}) {
		if ($action eq $value->{url}) {
			$name = $key;
			$page = $value->{page};
		}
	}

	# provide default for target page
	$page ||= 'wiki';

	# pass wiki parameters to page
	$CGI::values{name} = $name;
	$CGI::values{page} ||= $url;

	# actual page
	$CGI::values{mv_nextpage} = $page;
	
 	return 1;
}

package Vend::Config;

sub parse_wiki {
	my ($item, $settings) = @_;

	# parse routine is called once per catalog, regardless of configuration
	# directives
	return {} unless $settings;

	my ($name, $param, $value) = split(/\s+/, $settings);

	if ($param eq 'url') {
		# add pointer for our ActionMap
		Vend::Config::parse_action('ActionMap', "$value wiki");
	}
	elsif ($param eq 'formatter') {
		# add to our list of formatters
		my $class;
		
		if ($value =~ /::/) {
			# formatter with different namespace, breakout name
			$class = $value;
			my @frags = split(/::/, $value);
			$value = pop(@frags);
		}
		else {
			$class = "Wiki::Toolkit::Formatter::$value";
		}
		
		$C->{$item}->{$name}->{formatter}->{$value} = {class => $class};
	}
	elsif ($param eq 'backend' || $param eq 'dbname') {
		$C->{$item}->{$name}->{$param} = $value;
	}
	else {
		config_error("No code written yet for $param and $value.", $param, $value);
	}
	
	return $C->{$item};
}

1;
