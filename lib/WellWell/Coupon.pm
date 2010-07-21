# WellWell::Coupon - WellWell Coupons
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

package WellWell::Coupon;

use strict;
use warnings;

use Vend::Data;
use Vend::Tags;

# define [coupons] tag
Vend::Config::parse_tag('UserTag', 'coupons Order function code');
Vend::Config::parse_tag('UserTag', 'coupons AddAttr');
Vend::Config::parse_tag('UserTag', 'coupons HasEndTag');
Vend::Config::parse_tag('UserTag', 'coupons MapRoutine WellWell::Coupon::coupons');

my $last_error;

# [coupons]

sub coupons {
	my ($function, $code, $opt, $body) = @_;
	my ($coupon, $repo);

	if ($function eq 'validate' || $function eq 'redeem') {
		if ($coupon = lookup($code)) {
			if ($function eq 'validate') {
				return $coupon->code();
			}
			else {
				$coupon->redeem();
			}
		}
		else {
			Vend::Tags->error({name => 'coupons', set => $last_error, overwrite => 1});
		}
	}
	elsif ($function eq 'cancel') {
		# noop right now
	}
	elsif ($function eq 'display') {
		my (@out);
		
		if (exists $Vend::Session->{coupons}) {
			$repo = $Vend::Session->{coupons};

			for (@{$repo->[0]}) {
				my %hash = %{$repo->[1]->{$_}};
				
				$hash{coupon_number} = $_;
				$hash{discount_total} = Vend::Tags->subtotal({name => 'main', noformat => 1, nodiscount => 1})
															 - Vend::Tags->subtotal('main', 1);
				push (@out, Vend::Tags->uc_attr_list({hash => \%hash, body => $body}));
			}
			
			return join('', @out);
		}
	}
	
	return;
}

# Constructor for WellWell::Coupon class
sub new {
	my ($class) = shift;
	my ($self) = {code => shift};

	bless $self;

	while (@_ >= 2) {
		my $key = shift;
		$self->{$key} = shift;
	}

	return $self;
}

# Methods for WellWell::Coupon class
sub code {
	shift->{code};
}

sub redeem {
	my ($self) = shift;

	$self->log();
	$self->apply_discounts();
}

# apply_discounts - Apply discounts for coupon

sub apply_discounts {
	my ($self) = shift;
	my ($dbif, $set);
	
	unless ($dbif = database_exists_ref('coupon_discounts')) {
		die ::errmsg('Database missing: %s', 'coupon_discounts');
	}

	$set = $dbif->query(q{select code,subject,mode,value from coupon_discounts where coupon_code = '%s'}, $self->{code});

	for (@$set) {
		my ($code, $subject, $mode, $value) = @$_;

		if ($subject eq 'subtotal' && $mode eq 'percents') {
			if ($value <= 0 || $value >= 100) {
				::logError("Invalid coupon discount %s: $value%");
				next;
			}

			my $factor;

			$factor = 1 - $value / 100;

			Vend::Tags->discount({code => 'ALL_ITEMS', body => '$s * ' . $factor});

			$self->{discount} = $value;
			$Vend::Session->{coupons}->[1]->{$self->{coupon_number}}->{discount} = $value;
		}
	}
}


# Auxiliary functions
sub lookup {
	my ($coupon_number) = @_;
	my ($dbif, $set, $now, @clist, $coupon, $before_all);

	unless ($dbif = database_exists_ref('coupons')) {
		die ::errmsg('Database missing: %s', 'coupons');
	}

	$set = $dbif->query(q{select C.code,D.valid_from,D.valid_to from coupons C left join coupon_dates D on (C.code = D.coupon_code) where C.coupon_number = '%s' and C.inactive is FALSE order by D.valid_from ASC},
						$coupon_number);

	if (@$set) {
		$now = Vend::Tags->time({format => '%Y-%m-%d %H:%M:%S'});
		
		for (@$set) {
			# look for a proper candidate
			my ($code, $valid_from, $valid_to) = @$_;

			if ($valid_from) {
				if ($now lt $valid_from) {
					$before_all = 1;
					last;
				}
			}
			
			if ($valid_to) {
				next if $now gt $valid_to;
			}
				
			push (@clist, $_);
		}
	}

	unless (@clist) {
		if (@$set) {
			if ($before_all) {
				$last_error = ::errmsg('Coupon not yet active');
			}
			else {
				$last_error = ::errmsg('Coupon expired');
			}
		}
		else {
			$last_error = ::errmsg('Invalid coupon number.');
		}
		return;
	}

	return new WellWell::Coupon ($clist[0]->[0],
								 coupon_number => $coupon_number,
								 valid_to => $clist[0]->[1]);
}

# log - Log the coupon into the database and the session.

sub log {
	my ($self) = shift;
	my ($dbif, $entered, %record, $code);
	
	unless ($dbif = database_exists_ref('coupon_log')) {
		die ::errmsg('Database missing: %s', 'coupon_log');
	}

	$entered = Vend::Tags->time({format => '%Y-%m-%d %H:%M:%S'});
	
	%record = (coupon_code => $self->{code},
			   uid => $Vend::Session->{username} || 0,
			   session_id => $Vend::Session->{id},
			   entered => $entered);
	
	$code = $dbif->set_slice([{dml => 'insert'}], \%record);

	# apply discounts
	
	$Vend::Session->{coupons} ||= [[], {}];

	push (@{$Vend::Session->{coupons}->[0]}, $self->{coupon_number});
	$Vend::Session->{coupons}->[1]->{$self->{coupon_number}} = {code => $self->{code},
																valid_to => $self->{valid_to}};
	
	return $code;
}



1;
