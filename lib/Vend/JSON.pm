# Vend::JSON - Interchange JSON interface
#
# Copyright (C) 2012 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package Vend::JSON;

use strict;
use warnings;

use Vend::Config;
use Vend::File;
use Vend::Tags;

use JSON;

our $VERSION = '0.0010';

Vend::Config::parse_tag('UserTag', 'json Order function');
Vend::Config::parse_tag('UserTag', 'json HasEndTag');
Vend::Config::parse_tag('UserTag', 'json AddAttr');
Vend::Config::parse_tag('UserTag', 'json MapRoutine Vend::JSON::json');

sub json {
    my ($function, $opt, $body) = @_;
    my ($file, $file_content, $json);

    if ($file = $opt->{file}) {
        # read JSON from file
        unless ($file_content = readfile($file)) {
            die "Failed to retrieve file content from $file: $!\n";
        }

        $body = $file_content;

        $json = decode_json($body);
    }
    elsif ($opt->{ref}) {
        $json = encode_json($opt->{ref});
    }

    if ($function eq 'deliver') {
        Vend::Tags->deliver({type => 'application/json', body => $json});
        return;
    }

    return $json;
}
