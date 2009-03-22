# Vend::Table::AnyData
#
# $Id: AnyData.pm,v 1.3 2009/01/23 14:31:35 racke Exp $
#
# Copyright (C) 2009 Stefan Hornburg (Racke) <racke@linuxia.de>

package Vend::Table::AnyData;

use strict;
use warnings;
use vars qw($VERSION @ISA);

use DBI;
use Vend::Table::DBI;

use Vend::Data;
use Vend::File;

@ISA = qw(Vend::Table::DBI);
$VERSION = substr(q$Revision: 1.3 $, 10);

Vend::Config::parse_tag('UserTag', 'anydata Order table format name');
Vend::Config::parse_tag('UserTag', 'anydata AddAttr');
Vend::Config::parse_tag('UserTag', 'anydata MapRoutine Vend::Table::AnyData::anydata');

sub new {
	my ($class, $obj) = @_;
	bless $obj, $class;
}

sub anydata {
	my ($table, $format, $name, $opt) = @_;
	my ($dbh, $config, $ad_format);

	# verify file location
	unless (allowed_file($name)) {
		die ::errmsg("Access to file '%s' not allowed.", $name);
	}

	unless (-f $name) {
		die ::errmsg("File '%s' not found.", $name);
	}
	
	# check whether table name is in use
	if (database_exists_ref($table)) {
		die ::errmsg("Database name '%s' already in use.", $table);
	}
	
	# map format
	if (uc($format) eq 'TAB') {
		$ad_format = 'Tab';
	} else {
		$ad_format = $format;
	}
	
	# first load the data
	$dbh = DBI->connect('dbi:AnyData(RaiseError=>1):');
	$dbh->func($table, $ad_format, $name, 'ad_catalog');

	# grab columns
	my ($sth, $aref, $fref, $key);

	$config = {};
	
	$fref = Vend::Table::DBI::list_fields($dbh, $table, $config);
	$key = $fref->[0];
	
	# now turn it into an object
	my $obj = [$config, $table, $key, $fref, undef, $dbh];
	my $s = new Vend::Table::AnyData ($obj);
	$Vend::Database{$table} = $s;
	
	return $s;
}

1;
							

