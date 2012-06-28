# WellWell::Nitesi - WellWell Nitesi interface
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

package WellWell::Nitesi;

use strict;
use warnings;

use Nitesi::Query::DBI;

use Vend::Config;
use Vend::Data;

Vend::Config::parse_tag('UserTag', 'q MapRoutine WellWell::Nitesi::query');

sub query {
    my %dbif;
    my $product_table;

    unless ($Vend::Cfg->{Query}) {
        $product_table = $Vend::Cfg->{ProductFiles}->[0];

        unless ($dbif{products} = database_exists_ref($product_table)) {
            die ::errmsg('Database missing: %s', $product_table);
        }

        $Vend::Cfg->{Query} = Nitesi::Query::DBI->new(dbh => $dbif{products}->dbh);
    }
    
    return $Vend::Cfg->{Query};
}

1;

