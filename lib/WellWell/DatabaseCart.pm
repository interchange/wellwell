# WellWell::DatabaseCart - WellWell database cart routines
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

package WellWell::DatabaseCart;

use strict;
use warnings;

use Vend::Config;
use Vend::Data;
use Vend::Tags;

# DatabaseCart directive
Vend::Config::parse_directive('DatabaseCart', 'DatabaseCart database_cart');

Vend::Config::parse_tag('UserTag', 'database_cart_restore MapRoutine WellWell::DatabaseCart::cart_restore');
Vend::Config::parse_tag('UserTag', 'database_cart_clear MapRoutine WellWell::DatabaseCart::cart_clear');
Vend::Config::parse_tag('UserTag', 'database_cart_compare MapRoutine WellWell::DatabaseCart::cart_compare');

# Cart hook
sub cart_hook {
	my ($op, $cartname, $item, $changes) = @_;
	my ($cart);

	if ($cartname eq 'main') {
		$cartname = $Vend::Cfg->{DatabaseCart};
	}

	$cart = get_cart_by_name($cartname, 'cart', $Vend::Session->{username}, 1);
	
	if ($op eq 'add') {
		$cart->add_item($item);
	}
	elsif ($op eq 'delete') {
		$cart->delete_item($item);
	}
	elsif ($op eq 'modify' || $op eq 'combine') {
		$cart->modify_item($item, $changes);
	}
}

# Restoring database cart into session cart
sub cart_restore {
	my $cart;

	$cart = get_cart_by_name($Vend::Cfg->{DatabaseCart}, 'cart', $Vend::Session->{username});

	if ($cart) {
		$cart->restore();
	}
}

# Clearing database cart
sub cart_clear {
	my $cart;

	$cart = get_cart_by_name($Vend::Cfg->{DatabaseCart}, 'cart', $Vend::Session->{username});

	if ($cart) {
		$cart->clear();
	}
}

# Comparing database cart with session cart
sub cart_compare {
	my ($cart, $cart_products, $session_products, $cart_item, $session_item, $max_count, @diff);
	
	$cart = get_cart_by_name($Vend::Cfg->{DatabaseCart}, 'cart', $Vend::Session->{username});

	if ($cart) {
		$cart_products = $cart->item_list();
	}
	else {
		$cart_products = [];
	}
	
	$session_products = $Vend::Items;

	if (@$cart_products > @$session_products) {
		$max_count = @$cart_products;
	}
	else {
		$max_count = @$session_products;
	}
	
	for (my $i = 0; $i < $max_count; $i++) {
		unless ($cart_item = $cart_products->[$i]) {
			push (@diff, "Cart item $i missing.");
			next;
		}
		
		unless ($session_item = $session_products->[$i]) {
			push (@diff, "Session item $i missing.");
			next;
		}

		if ($cart_item->{code} ne $session_item->{code}) {
			push (@diff, "SKU differs for item $i: $cart_item->{code} vs $session_item->{code}.");
		}

		if ($cart_item->{quantity} ne $session_item->{quantity}) {
			push (@diff, "Quantity differs for item $i: $cart_item->{quantity} vs $session_item->{quantity}.");
		}
	}

	if (@diff) {
		return \@diff;
	}
}

# Cart object instantiation
sub get_cart_by_name {
	my ($name, $type, $uid, $create) = @_;
	my ($db_carts, $set, $code);

	$db_carts = database_exists_ref('carts');

	$set = $db_carts->query(q{select code from carts where name = '%s' and uid = '%s'},
							$name, $uid);

	if (@$set) {
		$code = $set->[0]->[0];
	}
	elsif ($create) {
		$code = $db_carts->autosequence();

		$code = $db_carts->set_slice($code, uid => $uid,
								  created => Vend::Tags->time({format => '%s'}),
								  type => $type,
								  name => $name);
	}

	if ($code) {
		return new WellWell::DatabaseCart($code);
	}
	
	return;
}

# constructor of DatabaseCart object
sub new {
	my ($class, $code) = @_;
	my ($self);

	$self->{code} = $code;
	
	bless $self;
	
	# set up database accessors
	$self->{db_carts} = database_exists_ref('carts');
	$self->{db_products} = database_exists_ref('cart_products');
	
	return $self;
}

sub add_item {
	my ($self, $item) = @_;

	unless (exists $item->{inactive} && $item->{inactive}) {
		$self->{db_products}->set_slice([$self->{code}, $item->{code}], quantity => $item->{quantity},
										position => 0);
		$self->touch();
	}
}

sub delete_item {
	my ($self, $item) = @_;

	$self->{db_products}->delete_record([$self->{code}, $item->{code}]);
	
	$self->touch();
}

sub modify_item {
	my ($self, $item, $changes) = @_;

	if ($changes->{quantity}) {
		$self->{db_products}->set_slice([$self->{code}, $item->{code}], quantity => $changes->{quantity});
	}

	$self->touch();
}

# update cart timestamp
sub touch {
	my ($self) = @_;
	my ($last_modified);

	$last_modified = Vend::Tags->time({format => '%s'});
	
	$self->{db_carts}->set_field($self->{code}, 'last_modified', $last_modified);
}

# clear cart (usually after order has been finished)
sub clear {
	my ($self) = @_;

	$self->{db_products}->query(qq{delete from cart_products where cart = $self->{code}});

	$self->touch();
}

# restore cart from database into session cart
sub restore {
	my ($self, $set, $item) = @_;
	
	# empty session cart first
	@$Vend::Items = ();

	$set = $self->{db_carts}->query(qq{select sku,quantity from cart_products where cart = $self->{code}});

	for (@$set) {
		$item = WellWell::Cart::cart_item(@$_);
		push (@$Vend::Items, $item);
	}

	return;
}

# return structure similar to session cart
sub item_list {
	my ($self, $complete) = @_;
	my ($set, @list);
	
	$set = $self->{db_products}->query(qq{select sku,quantity from cart_products where cart = $self->{code}});

	for (@$set) {
		my $item;
		
		if ($complete) {
			$item = WellWell::Cart::cart_item(@$_);
		}
		else {
			$item = {code => $_->[0], quantity => $_->[1]};
		}

		push(@list, $item);
	}

	return \@list;
}
	
package Vend::Config;

sub parse_database_cart {
	my ($item, $settings) = @_;

	# parse routine is called once per catalog, regardless of configuration
	# directives
	return {} unless $settings;

	$C->{$item} = $settings;

	# add to cart hook
	push(@{$C->{Hook}->{cart}}, \&WellWell::DatabaseCart::cart_hook);
	
	return $C->{$item};
}

1;
