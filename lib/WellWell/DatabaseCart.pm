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

    my $uid = $Vend::Session->{username} || $Vend::Session->{id};
	$cart = get_cart_by_name($cartname, 'cart', $uid, 1);
	
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

    my $uid = $Vend::Session->{username} || $Vend::Session->{id};
	$cart = get_cart_by_name($Vend::Cfg->{DatabaseCart}, 'cart', $uid);

	if ($cart) {
		$cart->restore();
	}
}

# Clearing database cart
sub cart_clear {
	my $cart;

    my $uid = $Vend::Session->{username} || $Vend::Session->{id};
	$cart = get_cart_by_name($Vend::Cfg->{DatabaseCart}, 'cart', $uid);

	if ($cart) {
		$cart->clear();
	}
}

# Comparing database cart with session cart
sub cart_compare {
	my ($cart, $cart_products, $session_products, $cart_item, $session_item, $max_count, @diff);

    my $uid = $Vend::Session->{username} || $Vend::Session->{id};
	$cart = get_cart_by_name($Vend::Cfg->{DatabaseCart}, 'cart', $uid);

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
                                  session_id => $Vend::Session->{id},
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
        my $opts = item_options_string($item);
		$self->{db_products}->set_slice([$self->{code}, $item->{code}, $opts],
                                        quantity => $item->{quantity},
										position => 0);
		$self->touch();
	}
}

sub delete_item {
	my ($self, $item) = @_;
    my $opts = item_options_string($item);
	$self->{db_products}->delete_record([$self->{code}, $item->{code}, $opts]);
	
	$self->touch();
}

sub modify_item {
	my ($self, $item, $changes) = @_;
    my $opts_str = item_options_string($item);

    # do a copy to avoid disasters
    my $item_copy = { %$item };

    foreach my $k (keys %$item_copy) {
        if (exists $changes->{$k}) {
            $item_copy->{$k} = $changes->{$k};
        }
    }
    my $new_opts_string = item_options_string($item_copy);

	if ($changes->{quantity}) {
		$self->{db_products}->set_slice([$self->{code}, $item->{code}, $opts_str],
                                        quantity => $changes->{quantity});
	}

    if ($new_opts_string ne $opts_str) {
		$self->{db_products}->set_slice([$self->{code}, $item->{code}, $opts_str],
                                        options => $new_opts_string);
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
    # take over the cart, if it exits with the same session
    if (my $sid = $Vend::Session->{id}) {
        $set = $self->{db_carts}->query(qq{select code from carts where session_id = '%s' and uid = session_id}, $sid);
        for my $cart (@$set) {
            $self->{db_carts}->query(qq{update cart_products set cart = $self->{code} where cart = $cart->[0]});
        }
    }

	$set = $self->{db_carts}->query(qq{select sku,quantity,options from cart_products where cart = $self->{code}});
	for (@$set) {
        my ($sku, $quantity, $opts) = @$_;
        my @args;
        if ($opts) {
            @args = ($sku, $quantity, item_options_string_to_hashref($opts));
        }
        else {
            @args = ($sku, $quantity);
        }
		$item = WellWell::Cart::cart_item(@args);
		push (@$Vend::Items, $item);
	}

    # update the session id of the cart
    $self->{db_carts}->set_field($self->{code}, session_id => $Vend::Session->{id});
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
	
sub item_options_string {
    my $itemref = shift;
    my $modifiers = "";
    my @mods;
    if (ref($Vend::Cfg->{UseModifier}) eq 'ARRAY') {
        for (@{$Vend::Cfg->{UseModifier}}) {
            if (exists $itemref->{$_} and defined $itemref->{$_}) {
                push @mods, $_ . "\0:\0" . $itemref->{$_};
            }
        }
    }
    if (@mods) {
         $modifiers = join("\0;\0", @mods);
    }
    return $modifiers;
}

sub item_options_string_to_hashref {
    my $item_string = shift;
    return unless $item_string;
    my @fields = split(/\0;\0/, $item_string);
    my %out;
    foreach my $f (@fields) {
        my ($k, $v) = split(/\0:\0/, $f);
        $out{$k} = $v;
    }
    return \%out;
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
