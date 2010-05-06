# Vend::Picture - Interchange image helper functions
#
# Copyright (C) 2004-2009 Stefan Hornburg (Racke) <racke@linuxia.de>.
# Copyright (C) 2010 Rok Ružič <rok.ruzic@informa.si>.
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

package Vend::Picture;

use strict;
use warnings;

use vars qw($CGI);

use IO::Scalar;

use Image::Size;
use Image::Magick;

use Vend::Config;
use Vend::File;
use Vend::Tags;

my $Tag = new Vend::Tags;

Vend::Config::parse_tag('UserTag', 'image_fontinfo Order function font');
Vend::Config::parse_tag('UserTag', 'image_fontinfo MapRoutine Vend::Picture::fontinfo');

Vend::Config::parse_tag('UserTag', 'image_info Order name');
Vend::Config::parse_tag('UserTag', 'image_info AddAttr');
Vend::Config::parse_tag('UserTag', 'image_info MapRoutine Vend::Picture::info');

Vend::Config::parse_tag('UserTag', 'image_resize Order name width height');
Vend::Config::parse_tag('UserTag', 'image_resize AddAttr');
Vend::Config::parse_tag('UserTag', 'image_resize MapRoutine Vend::Picture::resize');

Vend::Config::parse_tag('UserTag', 'image_superscribe Order name text color size font');
Vend::Config::parse_tag('UserTag', 'image_superscribe AddAttr');
Vend::Config::parse_tag('UserTag', 'image_superscribe MapRoutine Vend::Picture::superscribe');

sub info {
	my ($name, $opts) = @_;
	my ($width, $height, $type, $colors);
	my (@ret, %info);

	if ($opts->{colors}) {
		my $image;
		
		unless ($image = magick($name, $opts)) {
			return;
		}

		$colors = $image->Get('colors');
		return $colors unless($opts->{hash});
	}
	
	# first retrieve information about the image
	if ($opts->{cgi}) {
		# .. from form input
		@ret = imgsize(\$CGI::file{$name});
	} else {
		# .. from file
		unless (allowed_file($name)) {
			log_file_violation($name, 'Vend::Picture::info');
			return;
		}
		@ret = imgsize($name);
	}

	# check for errors
	unless (defined ($ret[0])) {
		::logError("Vend::Picture::info: $name: $ret[2]");
		return;
	}

	($width, $height, $type) = @ret;
	
	# collect information
	%info = (width => $width,
			 height => $height,
			 size => "${width}x${height}",
			 type => lc($type));

	# return requested information
	if ($opts->{hash}) {
		$info{colors} = $colors if $opts->{colors};
		return \%info;
	}
	
	return $info{size};
}

sub fontinfo {
	my ($function, $font) = @_;
	my ($magick);

	$magick = new Image::Magick;

	if ($function eq 'table') {
		my (@fonts, $out);
		
		@fonts = $magick->QueryFont();

		$out = '<table><tr>';
		$out .= join('', map {"<th>$_</th>"} ('Font Name', 'Description', 'Family', 'Style', 'Stretch', 'Weight', 'Encoding', 'Foundry', 'Format', 'Metrics', 'Glyphs'));
		$out .= '</tr>';

		for my $fontname (@fonts) {
			$out .= '<tr>';
			$out .= join('', map {"<td>$_</td>"} $magick->QueryFont($fontname));
			$out .= '</tr>';
		}
		
		$out .= '</table>';
		return $out;
	} elsif ($font) {
		my @info = $magick->QueryFont($font);
		unless (@info > 0) {
			::logError ("Error in QueryFont for $font");
		}
		::logError ("Info: @info");
		return join(',', @info);
	}
	
	return join(',', $magick->QueryFont());
}

sub border {
	my ($name, $color, $size, $opts) = @_;
	my ($image, $msg, $outfile, $mask);

	unless ($image = magick($name, $opts)) {
		return;
	}

	$msg = $image->[0]->Border(color => $color,
							   width => $size,
							   height => $size);
	
	if ($msg) {
		::logError("Vend::Picture::border: $msg");
		return;
	}

	# generate output file
	$outfile = $opts->{outfile} || $name;

	return Vend::Picture::write($image, $outfile);
}	
	
sub fit {
	my ($name, $width, $height, $opts) = @_;
	my ($image, $orig_width, $orig_height, $w_ratio, $h_ratio, $msg,
		$outfile, $mask);

	unless ($image = magick($name, $opts)) {
		return;
	}

	unless ($width && $height) {
		::logError('Vend::Picture::fit: width and height are required');
		return;
	}

	# determine ratios between original sizes and desired sizes
	$orig_width = $image->[0]->Get('width');
	$orig_height = $image->[0]->Get('height');

	$w_ratio = $orig_width / $width;
	$h_ratio = $orig_height / $height;

	# we resize either width or height
	unless ($opts->{downsize_only} && $w_ratio <= 1 && $h_ratio <= 1) {
		if ($w_ratio >= $h_ratio) {
			$msg = $image->[0]->Scale(width=> int($orig_width / $w_ratio),
									  height=> int($orig_height / $w_ratio));
		} else {
			$msg = $image->[0]->Scale(width=> int($orig_width / $h_ratio),
									  height=> int($orig_height / $h_ratio));
		}
		
		if ($msg) {
			::logError("Vend::Picture::fit: $msg");
			return;
		}
	}
	
	# generate output file
	$outfile = $opts->{outfile} || $name;

	return Vend::Picture::write($image, $outfile);
}

sub resize {
	my ($name, $width, $height, $opts) = @_;
	my ($image, $msg, $size, $outfile);
	
	unless ($image = magick($name, $opts)) {
		return;
	}

	if ($opts->{size}) {
		if ($opts->{size} =~ /^\s*(\d+)\s*x\s*(\d+)\s*$/) {
			# override width and height
			$width = $1;
			$height = $2;
		} else {
			::logError("Vend::Picture::resize: invalid size: $opts->{size}");
			return;
		}
	}
	$outfile = $opts->{outfile} || $name;

	# if we want both width and height to fit, we have to crop a bit
	if ($width && $height) {
		
		# Get the size and resize according to it
		my ($orig_width, $orig_height) = (0,0); #$image->[0]->Ping();
		$size = "${width}x$height";
		my $crop = $size;

		$orig_width = $image->[0]->Get('width');
		$orig_height = $image->[0]->Get('height');
		
		if ($orig_width < $orig_height){ # if landscape
			$size = "${width}x";
		}
		else {
			$size = "x$height";
		}

		$msg = $image->[0]->Thumbnail(geometry => $size);

		if ($msg) {
			::logError("Vend::Picture::resize: $msg");
			return;
		}

		$msg = $image->[0]->Set( Gravity => 'Center');

		if ($msg) {
			::logError("Vend::Picture::resize: $msg");
			return;
		}

		$msg = $image->[0]->Crop("$crop+0+0");

		if ($msg) {
			::logError("Vend::Picture::resize: $msg");
			return;
		}
		
		return Vend::Picture::write($image, $outfile);
	}
	elsif ($width || $height) {
		# shrink it by width or height
		if ($width) {
			$size = "${width}x";
		}
		else{
			$size = "x$height";
		}

		$msg = $image->[0]->Thumbnail(geometry => $size);

		if ($msg) {
			::logError("Vend::Picture::resize: $msg");
			return;
		}
		
		return Vend::Picture::write($image, $outfile);
	}
	else {
		::logError("Size '$size' is in incorrect format (123x123 is allowed) while resizing file '$name' to destination '$opts->{outputfile}'. Not resized.");
		return;
	}

	return 1;
}

sub scale {
	my ($name, $width, $height, $opts) = @_;
	my ($image, $msg, @args);

	unless ($image = magick($name, $opts)) {
		return;
	}

	my ($orig_width, $orig_height, $mask, $outfile);

	$outfile = $opts->{outfile} || $name;
	
	if ($width || $height) {
		# only one parameter given, get original size
		$orig_width = $image->[0]->Get('width');
		$orig_height = $image->[0]->Get('height');

		unless ($width) {
			# calculate new width
			$width = $orig_width  * ($height / $orig_height);
		}

		unless ($height) {
			# calculate new height
			$height = $orig_height * ($width / $orig_width);
		}
			
	} elsif (! $width && $height) {
		# no parameter given
		::logError ("Vend::Picture: missing parameter for width or height");
		return;
	}
		
	if ($msg = $image->[0]->Scale(width=>$width,height=>$height)) {
		::logError ("Vend::Picture: $msg");
		return;
	}

	return Vend::Picture::write($image, $outfile);
}

sub reduce_colors {
	my ($name, $colors, $opts) = @_;
	my ($image, $msg, $mask, $outfile);
	
	unless ($image = magick($name, $opts)) {
		return;
	}

	if ($msg = $image->[0]->Quantize(colors => $colors)) {
		::logError ("Vend::Picture: $msg");
		return;
	}

	$outfile = $opts->{outfile} || $name;

	return Vend::Picture::write($image, $outfile);
}

# Strip an image of all profiles and comments.
sub strip {
	my ($name, $opts) = @_;
	my ($image, $msg, $mask, $outfile);

	unless ($image = magick($name, $opts)) {
		return;
	}

	if ($msg = $image->[0]->Strip()) {
		::logError("Vend::Picture::strip: $msg");
		return;
	}

	$outfile = $opts->{outfile} || $name;

	return Vend::Picture::write($image, $outfile);
}

sub superscribe {
	my ($name, $text, $color, $size, $font, $opts) = @_;
	my ($image, $msg, $outfile, $mask);

	unless ($image = magick($name, $opts)) {
		return;
	}
	
	$outfile = $opts->{outfile} || $name;
		
	if ($msg = $image->[0]->Annotate(text => $text,
									 font => $font,
									 fill => $color,
									 gravity => $opts->{gravity} || 'Center',
									 pointsize => $size)) {
		::logError ("Vend::Picture: $msg");
		return;
	}

	return Vend::Picture::write($image, $outfile);		
}

# internal functions

# magick - creates an Image::Magick object

sub magick {
	my ($name, $opts) = @_;
	my (@args, $image, $msg);
	
	# first read in image
	if ($opts->{cgi}) {
		tie *IMG, 'IO::Scalar', \$CGI::file{$name};
		@args = (file => \*IMG);
	}
	elsif ($name) {
		@args = (filename => $name);
	}
	else {
		# missing parameter
		$Tag->error({name => 'picture',
					set => 'Picture missing.'});
		return;
	}
	
	$image = new Image::Magick;

	if ($msg = $image->Read(@args)) {
		::logError("failed to read picture: $msg");
		return;
	}

	return $image;
}

# write - saves the picture

sub write {
	my ($image, $outfile, $umask) = @_;
	my ($old_umask, $msg);

	if ($umask) {
		$old_umask = umask($umask);
	} else {
		$old_umask = umask(02);
	}

	if ($msg = $image->write($outfile)) {
		::logError("Vend::Picture::write: $msg");
		umask($old_umask);
		return;
	}

	return 1;
}

1;
