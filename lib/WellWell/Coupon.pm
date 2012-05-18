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

	if ($function eq 'validate') {
		if ($coupon = lookup($code)) {
			return $coupon->code();
		}
		else {
			Vend::Tags->error({name => 'coupons', set => $last_error, overwrite => 1});
		}

		return;
	}

	if ($function eq 'redeem') {
		if ($coupon = lookup($code)) {
			# check whether the coupon exists in the session first
			if (exists $Vend::Session->{coupons}) {
				$repo = $Vend::Session->{coupons};

				if (exists $repo->[1]->{$code}) {
					Vend::Tags->error({name => 'coupons', set => 'Coupon already in use', overwrite => 1});
					return;
				}
			}
			
			$coupon->redeem();
		}
		else {
			Vend::Tags->error({name => 'coupons', set => $last_error, overwrite => 1});
		}

		return;
	}
	
	if ($function eq 'cancel') {
		my ($coupon, $pos);
		
		if (exists $Vend::Session->{coupons}) {
			$repo = $Vend::Session->{coupons};

			if (exists $repo->[1]->{$code}) {
				# remove coupon from session hash
				$coupon = delete $repo->[1]->{$code};

				# reset discount(s)
				if ($coupon->{subject} eq 'subtotal') {
					Vend::Tags->discount({code => 'ENTIRE_ORDER', body => ''});
				}
				elsif ($coupon->{subject} eq 'product') {
					for my $sku (@{$coupon->{targets}}) {
						Vend::Tags->discount({code => $sku, body => ''});
					}
				}
				
				# remove coupon from session array
				delete $repo->[0]->[$coupon->{pos}];
				
				Vend::Tags->warnings('Coupon has been canceled');
				return;
			}
		}

		Vend::Tags->error({name => 'coupons', set => 'Coupon not in use'});
		return;
	}
	
	if ($function eq 'display') {
		my (@out, @links);
		
		if (exists $Vend::Session->{coupons}) {
			$repo = $Vend::Session->{coupons};

			for (@{$repo->[0]}) {
				my %hash = %{$repo->[1]->{$_}};
				
				$hash{coupon_number} = $_;
				$hash{discount_total} = Vend::Tags->subtotal({name => 'main', noformat => 1, nodiscount => 1})
															 - Vend::Tags->subtotal('main', 1);

				if ($opt->{zerohide} && $hash{discount_total} == 0) {
					# don't display anything
					return;
				}
				
				if ($hash{subject} eq 'subtotal') {
					$hash{target} = ' all items';
				}
				elsif ($hash{subject} eq 'product') {
					my (@links, $url);
					
					for (@{$hash{targets}}) {
						$url = Vend::Tags->area($_);
						push(@links, qq{<a href="$url">$_</a>});
					}
					
					$hash{target} = join(', ', @links);
				}
				
				push (@out, Vend::Tags->uc_attr_list({hash => \%hash, body => $body}));
			}
			
			return join('', @out);
		}

		return;
	}

	# Add a coupon to list of active coupons
	if ($function eq 'add'){	
		my ($dbif, $dbif_discounts,  %rec, %rec_discounts);

		unless ($dbif = database_exists_ref('coupons')) {
			die ::errmsg('Database missing: %s', 'coupons');
   	}
		
		unless ($dbif_discounts = database_exists_ref('coupon_discounts')) {
			die ::errmsg('Database missing: %s', 'coupon_discounts');
   	}

		# Check if coupon already exists
		my $set = $dbif->query(q{select coupon_number from coupons where coupon_number = '%s'}, $code);
		for (@$set) {
			my ($dbcode) = @$_;

			if($dbcode eq $code){
				die ::errmsg("Coupon '$code' already exists");
			}
		}

		if (! $code ) {
			die ::errmsg('code must be defined if you want to add coupons');
		}

		if (! $opt->{subject} ) {
			die ::errmsg('subject has to be defined (ie subtotal)');
		}

		if (! $opt->{mode} ) {
			die ::errmsg('mode has to be defined (ie percents or amount)');
		}
	
		if (! $opt->{value} ) {
			die ::errmsg('value has to be defined (ie 10 or 20)');
		}

		# user number of the coupon to add
		$rec{coupon_number} = $code;
		
		# used for writing in good for returns - amount to return
		if ($opt->{amount}) { 
			$rec{amount} = $opt->{amount};
		}
		# is coupon active?
		if ($opt->{inactive}) { 
			$rec{inactive} = $opt->{inactive};
		}	
		if ($opt->{count}) {
			$rec{count} = $opt->{count};
		}
		if ($opt->{comment}) {
			$rec{comment} = $opt->{comment};
		}
		if ($opt->{comment}) {
			$rec{comment} = $opt->{comment};
		}

		my $coupons_code = $dbif->set_slice(undef, \%rec);

		$rec_discounts{coupon_code}= $coupons_code;
		$rec_discounts{subject}= $opt->{subject};
		$rec_discounts{mode}= $opt->{mode};
		$rec_discounts{value}= $opt->{value};

		$dbif_discounts->set_slice(undef, \%rec_discounts);
		

		return "Coupon added with code: ".$code;
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
	my ($dbif, $dbif_targets, $set);
	
	unless ($dbif = database_exists_ref('coupon_discounts')) {
		die ::errmsg('Database missing: %s', 'coupon_discounts');
	}

	$set = $dbif->query(q{select code,subject,mode,value from coupon_discounts where coupon_code = '%s'}, $self->{code});

	for (@$set) {
		my ($code, $subject, $mode, $value) = @$_;
		my ($repo);

		if ($subject eq 'subtotal' && $mode eq 'percents') {
			if ($value <= 0 || $value >= 100) {
				::logError("Invalid coupon discount %s: $value%");
				next;
			}

			my $factor;

			$factor = 1 - $value / 100;

			Vend::Tags->discount({code => 'ENTIRE_ORDER', body => '$s * ' . $factor});

			# use only existing decimals
			$value =~ s/\.0+$//;
				
			$self->{discount} = $value;
			$self->{subject} = $subject;

			$repo = $Vend::Session->{coupons}->[1]->{$self->{coupon_number}};

			for (qw/discount subject/) {
				$repo->{$_} = $self->{$_};
			}
		}
		elsif ($subject eq 'product' && $mode eq 'percents') {
			my (@products);
			
			# apply discount only to certain products
			if ($value <= 0 || $value >= 100) {
				::logError("Invalid coupon discount %s: $value%");
				next;
			}

			# get products from coupon_targets
			@products = product_targets($code);
			
			my $factor;

			$factor = 1 - $value / 100;

			for (@products) {
				Vend::Tags->discount({code => $_, body => '$s * ' . $factor});
			}

			# use only existing decimals
			$value =~ s/\.0+$//;
				
			$self->{discount} = $value;
			$self->{subject} = $subject;
			$self->{targets} = \@products;

			$repo = $Vend::Session->{coupons}->[1]->{$self->{coupon_number}};

			for (qw/discount subject targets/) {
				$repo->{$_} = $self->{$_};
			}
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

# product_targets - Look up SKUs applicable for discount.

sub product_targets {
	my ($discount_code) = @_;
	my ($dbif, $set);

	unless ($dbif = database_exists_ref('coupon_targets')) {
		die ::errmsg('Database missing: %s', 'coupon_targets');
	}

	$set = $dbif->query(q{select value from coupon_targets where discount_code = '%s'},
						$discount_code);

	return map {$_->[0]} @$set;
}

# log - Log the coupon into the database and the session.

sub log {
	my ($self) = shift;
	my ($dbif, $entered, %record, $code, $pos, $session);
	
	unless ($dbif = database_exists_ref('coupon_log')) {
		die ::errmsg('Database missing: %s', 'coupon_log');
	}

	$entered = Vend::Tags->time({format => '%Y-%m-%d %H:%M:%S'});
	
	%record = (coupon_code => $self->{code},
			   uid => $Vend::Session->{username} || 0,
			   session_id => $Vend::Session->{id},
			   entered => $entered);
	
	$code = $dbif->set_slice([{dml => 'insert'}], \%record);

	$Vend::Session->{coupons} ||= [[], {}];

	push (@{$Vend::Session->{coupons}->[0]}, $self->{coupon_number});
	$pos = $#{$Vend::Session->{coupons}->[0]};

	$session = {code => $self->{code},
				subject => $self->{subject},
				targets => $self->{targets},
				log_code => $code,
				pos => $pos,
				valid_to => $self->{valid_to}};
	
	$Vend::Session->{coupons}->[1]->{$self->{coupon_number}} = $session;
	return $code;
}



1;
