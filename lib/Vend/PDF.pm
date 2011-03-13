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

use Template::Flute::Specification::XML;
use Template::Flute::HTML;
use Template::Flute::Database::Rose;
use Template::Flute::Style::CSS;
use Template::Flute;
use Template::Flute::I18N;
use Template::Flute::PDF;

use Vend::Config;
use Vend::Data;
use Vend::Tags;

# define [pdf] tag
Vend::Config::parse_tag('UserTag', 'pdf Order function specification template output');
Vend::Config::parse_tag('UserTag', 'pdf AddAttr');
Vend::Config::parse_tag('UserTag', 'pdf MapRoutine Vend::PDF::pdf');

# [pdf]
sub pdf {
	my ($function, $specification, $template, $output, $opt) = @_;
	my (%input, $locale, $ret);

	if ($function eq 'combine') {
		$ret = combine($output, $opt->{files}, $opt);
		return;
	}
	
	# input for Flute template
	if (exists $opt->{input}) {
		%input = %{$opt->{input}};
	}

	# parse specification file
	my ($xml_spec, $spec);

	$xml_spec = new Template::Flute::Specification::XML;

	unless ($spec = $xml_spec->parse_file($specification)) {
		die "$0: error parsing $xml_file: " . $xml_spec->error() . "\n";
	}

	# i18n
	my ($i18n, $sub);

	if ($opt->{locale}) {
		$locale = Vend::Tags->setlocale({get => 1});

		Vend::Tags->setlocale($opt->{locale});

		$sub = sub {
			my $text = shift;
			my $out;

			$out = Vend::Tags->filter({op => 'loc', body => $text});

			return $out;

		};
		
		$i18n = new Template::Flute::I18N ($sub);
		
	}

	# parse template
	my ($html_object);

	$html_object = new Template::Flute::HTML;

	$html_object->parse_file($template, $spec);

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

	$rose =  new Template::Flute::Database::Rose(dbh => database_exists_ref('products')->dbh());

	# create CSS object
	my ($css);

	$css = new Template::Flute::Style::CSS (template => $html_object);

	# create Template::Flute object and process template
	my ($flute);

	$flute = new Template::Flute (template => $html_object,
		i18n => $i18n,
		database => $rose,
		filters => $opt->{filters},
		values => $opt->{values},
	);

	$flute->process();

	# finally generate PDF
	my ($pdf);

	$pdf = new Template::Flute::PDF (template => $html_object,
		import => $opt->{import},
		page_size => $opt->{page_size});

	$pdf->process($output);

	if ($opt->{locale}) {
		Vend::Tags->setlocale($locale);
	}

	return;
}

sub combine {
	my ($output, $files, $opt) = @_;
	my ($pdf, $import);

	$pdf = new Template::Flute::PDF (file => $output, page_size => $opt->{page_size});

	$import = new Template::Flute::PDF::Import;

	for my $pdf_file (@$files) {
		$import->import(pdf => $pdf->{pdf}, file => $pdf_file);
	}

	$pdf->{pdf}->saveas();

	return $output;
}

1;
