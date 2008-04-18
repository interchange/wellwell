#!/usr/bin/perl
#
# Copyright 2008 by Jure Kodzoman (Yure), Tenalt d.o.o.  <jure@tenalt.com>
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
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA  02111-1307  USA.

use strict;
use warnings;

use AppConfig qw(:argcount :expand);
use Getopt::Long;
use File::Copy;
use File::NCopy;
use File::Path;
use DBIx::Easy;

my $config = new AppConfig (
	{
		CASE => 1,
		PEDANTIC => 0,
		CREATE => 0,
		GLOBAL => { ARGCOUNT => ARGCOUNT_HASH },
	},

	# Database settings

	"create_db!" => { DEFAULT => '1' }, # create db by default
	"db_admin=s",		# database admin username
	"db_admin_pass=s",	# database admin password
	"db_host=s",		# database hostname to connect to
	"db_user=s",		# database user to be used by ic
	"db_pass=s",		# database user password
	"db_type=s",		# pgsql or mysql
	"db_name=s",		# name of database
	"db_create_path=s",	# path to directory with create statements
	
	# Interchange settings

	"catalog_template=s",	# path to catalogs template
	"catalog_path=s",	# path to catalogs
	"catalogs_cfg=s",	# location of catalog.cfg file
	"cgi_url=s",		# cgi url eg. /cgi-bin/ic/
	"cgi_path=s",		# eg. /var/lib/cgi-bin/ic/

	# Web server settings

	"web_server=s",		# apache
	"web_conf_dir=s",	# directory in which to place generated conf
	"static_url=s",		# static url
	"static_dir=s",		# static dir (relative to catalog)

	# Catalog settings (settings that have to be set for each cat)
	
	"catalog_name=s",	# catalog name
	"server_name=s",	# server name eg. www.webshop.com
	"orders_email=s",	# orders email
);

$config->file('create.cfg');
$config->args();

# Check all obligatory configuration settings

if ( !$config->catalog_template() ){
	die "catalog_path is not defined in your configuration.";
}

if ( !$config->catalog_path() ){
	die "catalog_path is not defined in your configuration.";
}

if ( !$config->catalog_name() ){
	die "catalog_name is not defined in your configuration.";
}

if ( $config->db_type() !~ m/pg|mysql|postgres/i ){
	die "db_type is not defined in your configuration.";
}

if ( !$config->catalogs_cfg()  ){
	die "catalogs_cfg is not defined in your configuration.";
}

if ( !$config->cgi_url() ){
	die "cgi_url is not defined in your configuration.";
}

if ( ! $config->cgi_path() ){
	die "cgi_url is not defined in your configuration.";
}

if ( ! $config->server_name() ){
	die "server_name is not defined in your configuration.";
}

if ( ! $config->orders_email() ){
	die "orders_email is not defined in your configuration.";
}

my $catalog_template = $config->catalog_template();
my $catalog_path = $config->catalog_path();
my $catalogs_cfg = $config->catalogs_cfg();
my $cgi_path = $config->cgi_path();
my $cgi_url = $config->cgi_url();
my $static_dir = $config->static_dir() || 'static';
my $static_url = $config->static_url() || '/static';

my $catalog_name = $config->catalog_name();
my $server_name = $config->server_name();
my $orders_email = $config->orders_email();

my $db_type = $config->db_type;
my $db_host = $config->db_host || 'localhost';
my $db_user = $config->db_user || "ic_$catalog_name";
my $db_pass = $config->db_pass || mkpass(18);
my $db_name = $config->db_name || "ic_$catalog_name";
my $db_create_path = $config->db_create_path || "$catalog_path/$catalog_name/database";

##
## Create needed directories and link file
## 

# Check if we are copying a template or we have some var stuff there
# (could be made to just exclude var?)
if ( -d "$catalog_template/var/" ){
	die "var/ exists in your catalog template ($catalog_template). Please remove it before continuing";
}

if ( -d "$catalog_path/$catalog_name" ){
	die "There appears to be an existing catalog (or at least a directory of that name) on the location where you wish to create one ($catalog_path/$catalog_name)";
}

#Create catalog directory
mkdir("$catalog_path/$catalog_name");

# Copy catalog files from template directory to destination
my $cp = File::NCopy->new(recursive => 1);
$cp->copy("$catalog_template/*", "$catalog_path/$catalog_name")
	|| die "$0: Couldn't create catalog files in $catalog_path/$catalog_name: $!";

# Create var directories and assign proper permissions
mkpath(
	[
		"$catalog_path/$catalog_name/var/tmp",
		"$catalog_path/$catalog_name/var/session",
		"$catalog_path/$catalog_name/var/run",
		"$catalog_path/$catalog_name/var/log",
	], 0, 0770
) || die "$0: Couldn't create var directories: $!\n";

# Copy needed vlink file
copy("$cgi_path/vlink","$cgi_path/$catalog_name")
	or die "Copying link file failed: $!";

# Add an entry to catalogs.cfg
open FILE, ">>", "$catalogs_cfg" or die "Cannot open $catalogs_cfg file for writing: $!";
print FILE "Catalog $catalog_name $catalog_path/$catalog_name $cgi_url/$catalog_name";
close FILE;

##
## Database creation
##
## Creating a database (without structures), database user
## which will be used by Interchange to connect to the database
## and assign privileges to the user.

# We have to set a proper database type to indulge DBI.
# DBI uses Pg name and Interchange uses pgsql,
# so we are forced to using both

my $db_type_ic;
if( $db_type =~ m/pg|postgres/i ){
	$db_type    = 'Pg';
	$db_type_ic = 'pgsql';
}
elsif( $db_type =~ m/myslq/i){
	$db_type    = 'mysql';	
	$db_type_ic = 'mysql';
}

# In case we have db_create set, we also want to create the database
if ( $config->create_db() ){

	#For database creation we will need db_admin credentials
	my ($db_admin, $db_admin_pass);

	if ( ! $config->db_admin_pass() ){
		die qq{
			Database administrator password has to be supplied.
			Please enter db_admin_pass in your configuration file.
			or on command line call of "$0 --db_admin_pass value"
		}
	} 
	else {
		$db_admin_pass = $config->db_admin_pass();
	}


	#print "pass: $db_admin_pass"; #DEBUG

	if ( ! $config->db_admin() ){

		if ( $db_type eq 'Pg' ) {
			$db_admin = 'postgres';
		}
		elsif ( $db_type eq 'mysql' ) {
			$db_admin = 'root';
		}
		print qq{
			NOTICE: Database admin name (db_admin) is not defined in your configuration.
			We will use default for your db_type ($db_admin).
		};
	}
	
	# Now actually create database and users
	my @create_sqls, my $db_template;

	if ( $db_type eq 'Pg' ){

		$db_template = 'template1'; # db to connect to for creation

		# Statements to create database and proper privileges
		@create_sqls = (
			"CREATE USER $db_user WITH PASSWORD '$db_pass'",
			"CREATE DATABASE $db_name",
			"GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user",
		);

	}
	elsif ( $db_type eq 'mysql' ){

		$db_template = 'mysql'; # db to connect to for creation

		# HAS TO BE FIXED!
		# Statements to create database and proper privileges
		@create_sqls = (
			"CREATE USER $db_user WITH PASSWORD $db_pass",
			"CREATE DATABASE $db_name",
			"GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;",
		);

	}


	# Connect to database and execute statements
	my ($dbh, $sth);	
	$dbh = new DBIx::Easy ($db_type, $db_template, "$db_admin\@$db_host", $db_admin_pass);
	for my $sql (@create_sqls){
		$dbh->do_without_transaction($sql) or die $DBI::errstr;
	}
}


print completed($db_type, $db_host, $db_name, $db_user, $db_pass, 'heh', 'heh');

##
## Creating the database structures
##

# Connect to our catalog's database
my $dbh = new DBIx::Easy ($db_type, $db_name, "$db_user\@$db_host", $db_pass);

# Append database type to the directory name
$db_create_path= "$db_create_path/$db_type_ic";

# Read each file in database directory, 
# making each file a table definition in db
opendir(DIR, $db_create_path) or die "Can't open dir $db_create_path: $!";

while (defined(my $file = readdir(DIR))) {
	next if ( $file !~ /\.sql$/);

	my $file_path="$db_create_path/$file";

	#read the file into string
	my $content = do { local( @ARGV, $/ ) = $file_path ; <> } ;
	
	$file=~ s/\.\w+$//; #stripe extension before making it a table name
	$content = "CREATE TABLE $file ( $content )"; # append the create part

	# Execute create statement
	$dbh->do_without_transaction($content);
	print "SQL $content\n";
}
closedir(DIR);


##
## Configuring web server
##
## Depending on the web server you decided to choose, WellWell will try to give you
## a configuration file for setting up your catalog. Please note that this might not
## be the most optimal solution, but it should give a quick start.
##


##
## Populating site.txt
##
## This part fills site.txt file inside the database directory with catalog
## specific settings. This file is used by Interchange to detect information about
## a specific catalog
##

open FILE, ">", "$catalog_path/$catalog_name/database/site.txt" or die $!;
print FILE <<"EOF";
SERVER_NAME\t$server_name
CGI_URL\t$cgi_url
ORDERS_TO\t$orders_email
SQLDSN\tdbi:$db_type_ic:$db_name $db_user $db_pass
STATIC_URL\t$static_url
STATIC_DIR\t$static_dir
MV_TEMPLATE_DIR\ttemplates
MV_COMPONENT_DIR\tcomponents
EOF
close(FILE);

sub mkpass {
	my ($length) = @_;
	$length ||= 1;
	
	push( my @chars, ('0' ..' 9','a' .. 'z', 'A' .. 'Z'));

	my $out = '';
	$out .= $chars[rand(scalar(@chars))] for (1 .. $length);
	return $out;
}

sub completed {
	my($db_type, $db_host, $db_name, $db_user, $db_pass, $cat_path, $cat_url) = @_;

return <<"EOF";
Congratulations! You have just created an Interchange WellWell catalog.

-- Basic information about your catalog --

Database server: $db_type
Database host: $db_host
Database name: $db_name
Database username: $db_user
Database password: You can find your pass inside database/site.txt

URL of your catalog: $cat_url
Filesystem path to your catalog: $cat_path
EOF

}

