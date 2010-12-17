# Vend::PDF - PDF generation for Interchange
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

package Vend::PDF;

use Template::Zoom::Specification::XML;
use Template::Zoom::HTML;
use Template::Zoom::Database::Rose;
use Template::Zoom::Style::CSS;
use Template::Zoom;
use Template::Zoom::I18N;
use Template::Zoom::PDF;

use Vend::Config;
use Vend::Data;
use Vend::Tags;

# define [pdf] tag
Vend::Config::parse_tag('UserTag', 'pdf Order specification template output');
Vend::Config::parse_tag('UserTag', 'pdf AddAttr');
Vend::Config::parse_tag('UserTag', 'pdf MapRoutine Vend::PDF::pdf');

# [pdf]
sub pdf {
	my ($specification, $template, $output, $opt) = @_;
	my (%input);

	# input for Zoom template
	if (exists $opt->{input}) {
		%input = %{$opt->{input}};
	}

	# parse specification file
	my ($xml_spec, $spec);

	$xml_spec = new Template::Zoom::Specification::XML;

	unless ($spec = $xml_spec->parse_file($specification)) {
		die "$0: error parsing $xml_file: " . $xml_spec->error() . "\n";
	}

	# i18n
	my ($i18n, $sub);

	if ($opt->{locale}) {
		$sub = sub {
			my $text = shift;

			return Vend::Tags->filter({op => "loc.$opt->{locale}", body => $text});

		};
		$i18n = new Template::Zoom::I18N ($sub);
		
	}

	# parse template
	my ($html_object);

	$html_object = new Template::Zoom::HTML;

	$html_object->parse_template($template, $spec);

	for $list_object ($html_object->lists()) {
		# seed and check input
		$list_object->input(\%input);
	}	

	for $form_object ($html_object->forms()) {
		# seed and check input
		$form_object->input(\%input);
	}

	# create database object
	my ($rose);

	$rose =  new Template::Zoom::Database::Rose(dbh => database_exists_ref('products')->dbh());

	# create CSS object
	my ($css);

	$css = new Template::Zoom::Style::CSS (template => $html_object);

	# create Template::Zoom object and process template
	my ($zoom);

	$zoom = new Template::Zoom (template => $html_object,
		i18n => $i18n,
		database => $rose,
		filters => $opt->{filters},
		values => $opt->{values},
	);

	$zoom->process();

	# finally generate PDF
	my ($pdf);

	$pdf = new Template::Zoom::PDF (template => $html_object,
		import => $opt->{import});

	$pdf->process($output);

	return;
}

1;
