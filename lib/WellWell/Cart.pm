# WellWell::Cart - WellWell cart routines
#
# Copyright (C) 2009,2010,2011 Stefan Hornburg (Racke) <racke@linuxia.de>.
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

package WellWell::Cart;

use strict;
use warnings;

use constant CART_DEFAULT => 'main';

use Vend::Config;
use Vend::Tags;
use Vend::Data;

Vend::Config::parse_tag('UserTag', 'cart_add Order sku quantity cart');
Vend::Config::parse_tag('UserTag', 'cart_add AddAttr');
Vend::Config::parse_tag('UserTag', 'cart_add MapRoutine WellWell::Cart::cart_add');

Vend::Config::parse_tag('UserTag', 'cart_clear Order cart');
Vend::Config::parse_tag('UserTag', 'cart_clear AddAttr');
Vend::Config::parse_tag('UserTag', 'cart_clear MapRoutine WellWell::Cart::cart_clear');

Vend::Config::parse_tag('UserTag', 'cart_item Order sku quantity');
Vend::Config::parse_tag('UserTag', 'cart_item AddAttr');
Vend::Config::parse_tag('UserTag', 'cart_item MapRoutine WellWell::Cart::cart_item');

Vend::Config::parse_tag('UserTag', 'cart_refresh Order cart');
Vend::Config::parse_tag('UserTag', 'cart_refresh MapRoutine WellWell::Cart::cart_refresh');

Vend::Config::parse_subroutine('GlobalSub', 'cart_refresh WellWell::Cart::cart_refresh_form_action');

# [cart-item] - returns item hash ready to put it into cart

sub cart_item {
	my ($sku, $quantity, $opt) = @_;
	my ($db_products, $product_ref, %item);

	unless ($db_products = database_exists_ref('products')) {
		die errmsg("Database missing: %s", 'products');
	}
	
	$quantity ||= 1;
	
    %item = (code => $sku,
			 quantity => $quantity,
			 mv_mi => Vend::Tags->time({format => '%s'}) . sprintf('%06d', ++$Vend::Session->{pageCount}),
			 mv_si => 0);

	# get automodifiers
	if (ref($Vend::Cfg->{AutoModifier}) eq 'ARRAY') {
		Vend::Order::auto_modifier(\%item);
	}
	
	# apply possible overrides
	for (keys %item) {
		if ($opt->{$_}) {
			$item{$_} = $opt->{$_};
		}
	}
	
	if (ref($Vend::Cfg->{UseModifier}) eq 'ARRAY') {
		for (@{$Vend::Cfg->{UseModifier}}) {
			if (exists $opt->{$_}) {
				$item{$_} = $opt->{$_};
			}
		}
	}
	
	return \%item;
}

# [cart-add] - add item to cart

sub cart_add {
	my ($sku, $quantity, $cart, $opt) = @_;
	my ($itemref, $subname, $sub, $separate_item, $combref);

	$cart ||= CART_DEFAULT;
	
	$itemref = cart_item($sku, $quantity, $opt);
	
    WellWell::Core::hooks('run', 'cart', 'add', $cart, $itemref);

	if ($itemref->{error}) {
		# one of the hooks denied the item
		if ($itemref->{log_error}) {
			::logError('Adding item %s was denied: %s', $sku, $itemref->{error});
		}
		Vend::Tags->error({name => $sku, set => $itemref->{error}, overwrite => 1});

		# prevent error from leaking into subsequent cart actions
		delete $itemref->{error};
		return;
	}

	if ($itemref->{cart}) {
		# hook overrided cart name
		$cart = delete $itemref->{cart};
	}
	
	# now check whether the item is active
	if (exists $itemref->{inactive}
		&& $itemref->{inactive}) {
		Vend::Tags->error({name => $sku, set => 'Product has been discontinued', overwrite => 1});
		return;
	}
	
	# see if we can combine this item into cart items
	if ($subname = $Vend::Cfg->{SpecialSub}{separate_items}) {
		$sub = $Vend::Cfg->{Sub}{$subname} || $Global::GlobalSub->{$subname};
		$separate_item = $sub->($itemref);
	}
	else {
		$separate_item = $Vend::Cfg{SeparateItems};
	}

	if (!$separate_item && ($combref = combine_items($itemref, $cart))){
		WellWell::Core::hooks('run', 'cart', 'combine', $cart, $itemref, {quantity => $combref->{quantity}});
		return $combref;
	}
	
	# verify that number of items doesn't go out of bounds
	if ($Vend::Cfg->{OrderLineLimit} && @$Vend::Items >= $Vend::Cfg->{OrderLineLimit}) {
		::logError('Limit %s for number of items in the cart exceeded.',
				   $Vend::Cfg->{OrderLineLimit});
		return;
	}
	
    push(@{$::Carts->{$cart}}, $itemref);

    return $itemref;
}

# [cart-clear] - clear cart

sub cart_clear {
	my ($cart, $opt) = @_;
	my (@new_cart, $sku);

	$cart ||= CART_DEFAULT;
	
	for my $itemref (@{$::Carts->{$cart}}) {
		$sku = $itemref->{code};
		WellWell::Core::hooks('run', 'cart', 'delete', $cart, $itemref);
	
		if ($itemref->{error}) {
			# one of the hooks denied the item
			if ($itemref->{log_error}) {
				::logError('Removing item %s was denied: %s', $sku, $itemref->{error});
			}
			Vend::Tags->error({name => $sku, set => $itemref->{error}, overwrite => 1});

			# prevent error from leaking into subsequent cart actions
			delete $itemref->{error};
			
			push (@new_cart, $itemref);
		}
	}

    if (@{$::Carts->{$cart}} = @new_cart) {
		return 0;
	}

	return 1;
}

sub cart_refresh {
	my ($cart_name) = @_;
	my ($cart, $new_cart, $quantity, $itemref, $sku, $modifiers);

	$cart_name ||= CART_DEFAULT;

	$cart = $::Carts->{$cart_name};
	$new_cart = [];

	if ($CGI::values{mv_order_item}) {
		my (@oi, $sku);

		@oi = @{$CGI::values_array{mv_order_item}};

		if (@oi == 1) {
			# Adding single item from product order link/button

			$sku = $oi[0];
			$modifiers = {};
		
			if (ref($Vend::Cfg->{UseModifier}) eq 'ARRAY') {
				for (@{$Vend::Cfg->{UseModifier}}) {
					if (exists $CGI::values{"mv_order_$_"}) {
						$modifiers->{$_} = $CGI::values{"mv_order_$_"};
					}
				}
			}

			return cart_add($sku,
				 $CGI::values{mv_order_quantity} || 1,
							CART_DEFAULT,
				 $modifiers);

		}
		else {
			# Adding multiple items from result lists
			for (my $i = 0; $i < @{$CGI::values_array{mv_order_item}}; $i++) {
				$sku = $CGI::values_array{mv_order_item}->[$i];

				next unless $CGI::values_array{mv_order_quantity}->[$i];

				cart_add($sku,
						 $CGI::values_array{mv_order_quantity}->[$i] || 1,
						 CART_DEFAULT,
						 $modifiers);
			}
	
			return;
		}
	}
	
	return 1 unless defined $CGI::values{"quantity0"};

	# Refreshing cart
	foreach my $i (0 .. $#$cart) {
		my $modref = {};
		
		$itemref = $cart->[$i];
		$quantity = $CGI::values{"quantity$i"};

		# trim quantity
		$quantity =~ s/^\s+//;
		$quantity =~ s/\s+$//;
		
		if (defined $quantity) {
			if ($quantity =~ /^(\d+)$/ && $quantity != $itemref->{quantity}) {
				if ($quantity == 0) {
					WellWell::Core::hooks('run', 'cart', 'delete', CART_DEFAULT, $itemref);

					if ($itemref->{error}) {
						if ($itemref->{log_error}) {
							::logError('Removal of item %s was denied: %s', $itemref->{code}, $itemref->{error});
						}
						Vend::Tags->error({name => $itemref->{code}, set => $itemref->{error}, overwrite => 1});
						# prevent error from leaking into subsequent cart actions
						delete $itemref->{error};
						
						$quantity = $itemref->{quantity};
					}
					else {
						# deleting the item by omission
						next;
					}
				}
				$modref->{quantity} = $quantity;
			}
		}

		# checking whether any modifier changed
		if (ref($Vend::Cfg->{UseModifier}) eq 'ARRAY') {
			for (@{$Vend::Cfg->{UseModifier}}) {
				if (exists $CGI::values{"$_$i"}
					&& $CGI::values{"$_$i"} ne $itemref->{$_}) {
					$modref->{$_} = $CGI::values{"$_$i"};
				}
			}
		}

		if (keys %$modref) {
		    WellWell::Core::hooks('run', 'cart', 'modify', CART_DEFAULT, $itemref, $modref);

			if ($itemref->{error}) {
				if ($itemref->{log_error}) {
					::logError('Modification of item %s was denied: %s', $itemref->{code}, $itemref->{error});
				}
				Vend::Tags->error({name => $itemref->{code}, set => $itemref->{error}, overwrite => 1});
				%$modref = ();
				
				# prevent error from leaking into subsequent cart actions
				delete $itemref->{error};
			}
			
			for (keys %$modref) {
				$itemref->{$_} = $modref->{$_};
			}
		}
		
		push (@$new_cart, $itemref);
	}

	@$cart = @$new_cart;
}

sub cart_refresh_form_action {
	# let [cart-refresh] deal with that
	cart_refresh();
	
	if ($CGI::values{mv_nextpage} eq $Vend::Cfg->{ProcessPage}) {
		# skip virtual pages for determing shopping cart page
		delete $CGI::values{mv_nextpage};
	}
	
	unless ($CGI::values{mv_nextpage}) {
		$CGI::values{mv_nextpage} = $CGI::values{mv_orderpage}
			|| find_special_page('order');
	}

	return 1;
}

sub combine_items {
	my ($item, $cart) = @_;
	
 	ITEMS: for my $cartitem (@{$::Carts->{$cart}}) {
		if ($item->{'code'} eq $cartitem ->{'code'}){
			if (ref($Vend::Cfg->{UseModifier}) eq 'ARRAY'){
				for my $mod (@{$Vend::Cfg->{UseModifier}}){
					next ITEMS unless($item->{$mod} eq $cartitem->{$mod});
				}					
			}
			
			$cartitem->{'quantity'} += $item->{'quantity'};
			return $cartitem;
		}
	}

	return;
}

1;
